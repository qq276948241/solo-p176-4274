# Project 176 架构设计文档

---

## 一、技术栈与版本

| 组件 | 版本/选择 | 说明 |
|-------|-----------|------|
| 框架 | Ruby on Rails 8.1.3（API-only 模式） | `config.api_only = true`，默认只加载 API 所需的中间件 |
| Web Server | Puma 5+ | Rails 默认的生产级 Web Server |
| 数据库 | PostgreSQL（通过 pg gem 访问，监听 Docker 容器的 15432 端口 | 所有数据持久化 |
| 序列化 | active_model_serializers 0.10.x | 把 ActiveRecord 对象序列化为 JSON |
| 后台任务 | Solid Queue / Solid Cache | Rails 8 官方的数据库级队列与缓存（基于 PostgreSQL） |
| 认证 | 自建 Token（随机 64 位 hex，存储在 tokens 表） | 非 JWT，纯数据库 Token |
| 部署 | Kamal | 37signals 出品的基于 MRSK 极简部署工具 |
| 加速 | Thruster / Bootsnap | Thruster 提供 HTTP 静态资源缓存与 X-Sendfile；Bootsnap 加速启动 |

---

## 二、目录结构

```
project176/
├── app/
│   ├── controllers/
│   │   ├── api/v1/              # API 控制器（按 RESTful 资源组织）
│   │   │   ├── auth_controller.rb          # 登录/登出/刷新/校验 Token
│   │   │   ├── members_controller.rb       # 会员管理
│   │   │   ├── coaches_controller.rb       # 教练管理
│   │   │   ├── coach_schedules_controller.rb  # 教练排班
│   │   │   ├── bookings_controller.rb      # 课程预约
│   │   │   └── products_controller.rb      # 商品（商城）
│   │   └── concerns/
│   │       ├── authenticable.rb            # Token 认证过滤器（before_action）
│   │       └── error_handlable.rb         # 统一异常捕获与 render_error/render_success 封装
│   ├── models/
│   │   ├── token.rb               # API 访问令牌
│   │   ├── member.rb              # 会员（次卡/月卡）
│   │   ├── coach.rb             # 教练
│   │   ├── coach_schedule.rb      # 教练排班时段
│   │   ├── booking.rb            # 预约单
│   │   └── product.rb            # 商品
│   ├── serializers/              # 每个 Model 对应一个 Serializer
│   ├── services/
│   │   └── product_query_service.rb   # 商品列表搜索/筛选/排序（Service Object 模式）
│   ├── errors/                 # 业务异常类（继承 ApiError）
│   ├── jobs/                   # Active Job 基类
│   └── mailers/                # Action Mailer 基类
├── lib/
│   └── force_utf8_params_middleware.rb  # Rack 中间件：强制 HTTP 参数为 UTF-8 编码
├── config/
│   ├── application.rb         # 应用全局配置（含中间件插入、默认编码）
│   ├── database.yml         # PostgreSQL 连接配置
│   └── routes.rb          # API v1 路由定义
├── db/
│   ├── migrate/              # 数据库迁移
│   └── seeds.rb              # 种子数据
└── test/
    ├── models/               # Model 单元测试
    ├── controllers/          # Controller 集成测试
    ├── services/            # Service 单元测试
    └── integration/         # HTTP 级集成测试（含中文搜索等边界场景）
```

---

## 三、MVC 分层职责

### 3.1 Model 层（业务核心）

- **Model 承担业务规则的最终防线**：所有数据校验、状态流转、业务计算都放在 Model 里，Controller 只做 HTTP 协议相关的事。
- 每个 Model 都有对应的常量（如 `CATEGORIES`、`STATUSES`）定义枚举值，配合 `validates inclusion` 做数据库级约束。
- 常用查询都封装成 scope（如 `Member.active`、`Booking.upcoming`），避免在 Controller 里写裸 SQL。
- **领域方法**：比如 `Member#consume_session!`（扣次）、`Booking#cancel!`（取消预约并退还次数）、`CoachSchedule#can_cancel?`（判断是否在 2 小时内）——这些都封装了事务和异常抛出。

### 3.2 Controller 层（协议适配）

- Controller **不直接写业务逻辑**，只做三件事：
  1. 接收并解析 HTTP 参数
  2. 调用 Model / Service 完成业务
  3. 调用 `render_success` / `render_error` 输出 JSON
- 通过 `Authenticable` concern 注入 `before_action :authenticate_token!`，默认所有接口需 Token（AuthController 的 `login` 用 `skip_before_action` 豁免）。
- 通过 `ErrorHandlable` concern 的 `rescue_from` 捕获所有异常，统一输出 `{ error: { message, code, status } }` 格式。

### 3.3 View / Serializer 层（JSON 输出）

- 用 `active_model_serializers` 做序列化，每个 Model 对应一个 `*Serializer`。
- Controller 中直接 `render_success(data: serializer_instance)`，Serializer 决定输出哪些字段、是否嵌套关联对象。

### 3.4 Service 层（复杂查询与复用）

- 目前只有 `ProductQueryService`，承担商品列表的搜索、筛选、排序逻辑的拼装。
- 选择用 Service Object 是因为商品列表同时有 4 个维度（关键词 q、分类 category、成色 condition、状态 status + 排序 sort），拼装逻辑放在 Controller 里会非常臃肿，而且未来其他地方（比如管理后台）可能也要复用同一套查询。

---

## 四、核心业务模块

### 4.1 认证与授权（Auth）

**目的**：保护所有 API 接口，只有持有有效 Token 的请求才能访问。

**数据模型**：`Token` 表存储 `token`（64 位 hex 随机串）、`expires_at`（过期时间）、`description`（用途描述）。

**生命周期**：
- 生成：`Token.generate(description, duration)` → 写入数据库，默认 30 天有效
- 校验：`Token.authenticate(token_string)` → 查库+校验过期，过期抛 `TokenExpiredError`
- 刷新：`token.refresh!` → 延长过期时间
- 吊销：`token.revoke!` → 把过期时间设为当前时间前 1 秒（软删除）

**登录逻辑**：`/api/v1/auth/login` 接收 `username`/`password`，比对环境变量 `API_USERNAME`/`API_PASSWORD`（默认 admin / admin123），成功则生成 Token 返回。

### 4.2 会员管理（Members）

**两种卡类型**：
- `prepaid`（次卡）：靠 `remaining_sessions` 字段记录剩余次数
- `monthly`（月卡）：靠 `monthly_start_date` ~ `monthly_end_date` 字段记录有效期

**核心能力**：
- `can_book?`：判断会员是否可预约（状态 active 且卡有效）
- `consume_session!`：扣减次数（次卡扣 1 次；月卡仅校验有效期不扣次）
- `refund_session!`：退还次数（仅次卡生效）
- `booking_eligibility`：返回结构化的 eligibility 信息，供前端展示
- 扩展接口：`recharge`（充次）、`extend_membership`（续期月卡）、`eligibility`（查询资格）

### 4.3 教练排班（Coach Schedules）

**核心约束**：
- 每个教练同一时段只能有一个排班（`Coach#has_schedule_conflict?` 校验）
- 不能创建过去日期的排班
- 排班有 `max_bookings` 字段控制该时段最多可预约人数

**批量排班**：`CoachSchedule.batch_create_weekly_schedule` 接收 `day_of_week + start_time + end_time` 数组，一次性生成某一周的排班。

**可用时段查询**：`Coach#available_slots_for_date` 返回指定日期下仍有空位的排班。

### 4.4 课程预约（Bookings）

**预约创建时的校验链**（全部在 `Booking` 的 `validate` 回调里按顺序执行）：
1. 会员状态 active？→ 否则 `MemberInactiveError`
2. 教练状态 active？→ 否则 `CoachInactiveError`
3. 排班是否已满？→ 否则 `SlotFullError`
4. 排班是否已过？→ 否则 `PastDateError`
5. 排班状态是否 available？→ 否则 `slot_unavailable`
6. 会员卡是否有效（次卡次数>0 或 月卡在有效期内）→ 对应异常

**状态流转**：
- `booked` → `cancel!`（需距开始 ≥2 小时，退还次数）
- `booked` → `force_cancel!`（管理员强制取消，不校验时间，退次）
- `booked` → `complete!`（完成，扣次）
- `booked` → `mark_as_no_show!`（爽约，仍扣次）

**2 小时取消规则**：`CoachSchedule#can_cancel?` 判断 `start_datetime - now >= 2.hours`，不满足抛 `CancellationTooLateError`。

### 4.5 商品（Products）

**领域**：器材、补剂、服饰、配件、课程五类商城商品。

**列表查询**：由 `ProductQueryService` 统一处理，支持：
- 关键词 `q`：对 `title` 和 `description` 做 LIKE 模糊匹配（SQL 注入通过 `sanitize` 转义 `%_\` 通配符）
- 分类 `category`、成色 `condition`、状态 `status` 精确过滤
- 排序 `sort`：`published_desc`（默认）、`published_asc`、`price_desc`、`price_asc`

---

## 五、HTTP 请求完整链路

```
客户端 HTTP 请求
    │
    ▼
Puma（Web Server，监听端口）
    │
    ▼
ForceUtf8ParamsMiddleware（lib/force_utf8_params_middleware.rb）
    │   作用：在 Rack 层强制 QUERY_STRING 和 rack.input 为 UTF-8 编码
    │   解决 Windows 下中文参数乱码导致 LIKE 查询返回空的问题
    │
    ▼
Rails 路由（config/routes.rb）
    │   匹配 /api/v1/* 到对应 Controller#action
    │
    ▼
Authenticable（before_action，app/controllers/concerns/authenticable.rb）
    │   1. 从 Authorization 头提取 Bearer Token
    │   2. 调用 Token.authenticate 校验有效性
    │   3. 失败抛 UnauthorizedError / TokenExpiredError
    │
    ▼
Controller Action
    │   1. 接收 params（可能经 ProductQueryService 等 Service 处理
    │   2. 调用 Model 层方法完成业务
    │   3. 业务异常被 rescue_from 捕获
    │
    ▼
ErrorHandlable（app/controllers/concerns/error_handlable.rb）
    │   rescue_from 统一捕获异常 → render_error
    │   正常路径 → render_success / render_paginated
    │
    ▼
active_model_serializers 序列化 Model → JSON
    │
    ▼
客户端收到响应
```

---

## 六、数据库表与关联

### ER 关系图（外键）

```
tokens（无外键，独立表）

members ──┐
            │ 1
            │
            │ N
          bookings ── N:1 ── coach_schedules ── N:1 ── coaches

products（无外键，独立表）
```

### 各表字段概览

| 表名 | 关键字段 | 外键 |
|-------|---------|------|
| **tokens** | id, token(唯一索引), expires_at, description | 无 |
| **members** | id, name, phone(唯一索引), card_type(prepaid/monthly), status(active/inactive), remaining_sessions, monthly_start_date, monthly_end_date | 无 |
| **coaches** | id, name, phone(唯一索引), status, specialty | 无 |
| **coach_schedules** | id, coach_id, date, start_time, end_time, status(available/unavailable), max_bookings | coach_id → coaches.id |
| **bookings** | id, member_id, coach_schedule_id, status(booked/cancelled/completed/no_show), consumed(boolean) | member_id → members.id；coach_schedule_id → coach_schedules.id |
| **products** | id, title, category, condition(new/like_new/good/fair), status, price, description, published_at | 无 |

### 级联策略

- 删除 member → `dependent: :destroy`：删除会员时级联删除其所有预约
- 删除 coach → `dependent: :destroy`：删除教练时级联删除其所有排班，排班再级联删除预约
- 删除 coach_schedule → `dependent: :destroy`：删除排班时级联删除其预约

---

## 七、统一错误处理

所有业务异常定义在 `app/errors/`，全部继承自 `ApiError`，每个异常有 `status`（HTTP 状态码）、`code`（机器可读错误码）、`message`（人类可读描述）、`details`（可选细节）。

**已定义的业务异常：

| 异常类 | HTTP 状态 | 场景 |
|--------|-----------|------|
| UnauthorizedError | 401 | 未携带 Token 或 Token 无效 |
| TokenExpiredError | 401 | Token 已过期 |
| MemberInactiveError | 422 | 会员状态异常 |
| CoachInactiveError | 422 | 教练状态异常 |
| CardExpiredError | 422 | 月卡已过期 |
| InsufficientSessionsError | 422 | 次卡次数不足 |
| InvalidCardTypeError | 422 | 无效卡类型 |
| SlotFullError | 409 | 预约时段已满 |
| CancellationTooLateError | 422 | 距开始不足 2 小时，不能取消 |
| CoachScheduleConflictError | 409 | 教练排班冲突 |
| InvalidTimeRangeError | 422 | 排班结束时间早于等于开始时间 |
| PastDateError | 422 | 操作过去的日期 |

**统一响应格式**：

```json
{
  "error": {
    "message": "预约时段已满",
    "code": "slot_full",
    "status": 409
  }
}
```

开发/测试环境下 500 错误还会附带 `details` 字段包含异常类和堆栈，生产环境会隐藏。

---

## 八、通用能力封装

### 8.1 分页

在 `ErrorHandlable` concern 中提供 `render_paginated(relation, serializer, options:)` 方法：
- URL 参数：`page`（页码，默认 1）、`per_page`（每页条数，默认 20，最大 100）
- 返回格式：

```json
{
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_count": 100,
    "total_pages": 5
  }
}
```

### 8.2 编码处理（UTF-8 强制）

三层防护确保中文参数不乱码：
1. **应用层**：`config/application.rb` 中设置 `Encoding.default_external/internal = UTF-8`
2. **Rack 中间件**：`ForceUtf8ParamsMiddleware` 在请求进入 Rails 前强制 `QUERY_STRING` 和 `rack.input` 为 UTF-8
3. **Service 层**：`ProductQueryService#ensure_utf8` 对每个输入参数做最终兜底，兼容 GBK、ASCII-8BIT、UTF-8 三种编码输入

### 8.3 Service Object 模式

复杂查询（如商品多条件筛选）抽成独立 Service 类，遵循以下约定：
- 构造函数接收 `scope` 和 `params`
- `call` 方法返回最终的 Relation（或其他结果）
- 内部用 `normalize_params` 兼容 `ActionController::Parameters` 和普通 Hash
- 所有筛选条件严格区分 `nil`（不处理）和空字符串（不处理），避免 `blank?` 过于宽松的语义

### 8.4 测试

- 使用 Rails 原生 `TestUnit`（Minitest），不使用 RSpec。
- 分层测试分四个目录：models、controllers、services、integration。
- 测试不使用 parallelize（Windows 下 PostgreSQL + 多线程会段错误），默认单进程运行。
