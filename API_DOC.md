# 私教健身工作室会员管理 API

## 概述

基于 Ruby on Rails 的私教健身工作室会员管理系统 API，包含会员管理、课程预约、教练排班三大模块。

## 基础信息

- **基础URL**: `/api/v1`
- **认证方式**: Token 认证
- **数据格式**: JSON
- **数据库**: PostgreSQL

## 认证

### 登录获取 Token

```
POST /api/v1/auth/login
```

请求体：
```json
{
  "username": "admin",
  "password": "admin123"
}
```

响应：
```json
{
  "data": {
    "token": "xxxxxx...",
    "expires_at": "2026-07-28T09:00:00Z",
    "description": "API Access Token"
  }
}
```

### 在请求中使用 Token

在请求头中添加：
```
Authorization: Bearer <your-token>
```

### 其他认证接口

```
POST   /api/v1/auth/logout      # 注销 Token
POST   /api/v1/auth/refresh     # 刷新 Token
GET    /api/v1/auth/verify      # 验证 Token
```

## 错误响应格式

所有错误响应统一格式：
```json
{
  "error": {
    "message": "错误描述",
    "code": "错误码",
    "status": 400
  }
}
```

### 常见错误码

| 状态码 | 错误码 | 描述 |
|--------|--------|------|
| 401 | unauthorized | 无效的认证令牌 |
| 401 | token_expired | 认证令牌已过期 |
| 404 | not_found | 资源不存在 |
| 409 | slot_full | 时段已满 |
| 409 | coach_schedule_conflict | 教练排班冲突 |
| 422 | card_expired | 月卡已过期 |
| 422 | insufficient_sessions | 次卡次数不足 |
| 422 | invalid_card_type | 无效的卡类型 |
| 422 | cancellation_too_late | 距离开始时间不足2小时 |
| 422 | member_inactive | 会员状态异常 |
| 422 | coach_inactive | 教练状态异常 |
| 422 | invalid_time_range | 时间范围无效 |
| 422 | past_date | 不能预约过去的日期 |
| 422 | validation_failed | 数据验证失败 |

## 会员管理 API

### 会员列表
```
GET /api/v1/members
```

查询参数：
- `status`: 状态筛选 (active/inactive)
- `card_type`: 卡类型筛选 (prepaid/monthly)
- `keyword`: 姓名关键词搜索

### 创建会员
```
POST /api/v1/members
```

请求体：
```json
{
  "member": {
    "name": "张三",
    "phone": "13800138001",
    "card_type": "prepaid",
    "remaining_sessions": 10
  }
}
```

或月卡会员：
```json
{
  "member": {
    "name": "李四",
    "phone": "13800138002",
    "card_type": "monthly",
    "monthly_start_date": "2026-06-01",
    "monthly_end_date": "2026-06-30"
  }
}
```

### 会员详情
```
GET /api/v1/members/:id
```

### 更新会员
```
PUT /api/v1/members/:id
```

### 删除会员
```
DELETE /api/v1/members/:id
```

### 查询预约资格
```
GET /api/v1/members/:id/eligibility
```

响应：
```json
{
  "data": {
    "eligible": true,
    "type": "prepaid",
    "remaining": 10
  }
}
```

### 次卡充值
```
POST /api/v1/members/:id/recharge
```

请求体：
```json
{
  "sessions": 10
}
```

### 月卡续期
```
POST /api/v1/members/:id/extend_membership
```

请求体：
```json
{
  "months": 1,
  "start_date": "2026-07-01"
}
```

### 会员预约记录
```
GET /api/v1/members/:id/bookings
```

查询参数：
- `status`: 状态筛选
- `upcoming=true`: 仅显示即将到来的预约
- `past=true`: 仅显示历史预约

## 教练管理 API

### 教练列表
```
GET /api/v1/coaches
```

查询参数：
- `status`: 状态筛选
- `specialty`: 专长筛选
- `keyword`: 姓名关键词

### 创建教练
```
POST /api/v1/coaches
```

请求体：
```json
{
  "coach": {
    "name": "王教练",
    "phone": "13900139001",
    "specialty": "增肌、力量训练",
    "status": "active"
  }
}
```

### 教练详情
```
GET /api/v1/coaches/:id
```

### 更新教练
```
PUT /api/v1/coaches/:id
```

### 删除教练
```
DELETE /api/v1/coaches/:id
```

### 教练本周排班
```
GET /api/v1/coaches/:id/weekly_schedules?date=2026-06-28
```

### 教练某日可用时段
```
GET /api/v1/coaches/:id/available_slots?date=2026-06-28
```

## 教练排班 API

### 排班列表
```
GET /api/v1/coach_schedules
```

查询参数：
- `coach_id`: 教练ID筛选
- `date`: 具体日期
- `week_date`: 周日期（返回该周排班）
- `status`: 状态筛选

### 创建排班
```
POST /api/v1/coach_schedules
```

请求体：
```json
{
  "coach_schedule": {
    "coach_id": 1,
    "date": "2026-07-01",
    "start_time": "09:00",
    "end_time": "10:00",
    "max_bookings": 1,
    "status": "available"
  }
}
```

### 批量创建周排班
```
POST /api/v1/coach_schedules/batch_create_weekly
```

请求体：
```json
{
  "coach_id": 1,
  "week_date": "2026-06-28",
  "time_slots": [
    {
      "day_of_week": 1,
      "start_time": "09:00",
      "end_time": "10:00",
      "max_bookings": 1
    },
    {
      "day_of_week": 3,
      "start_time": "19:00",
      "end_time": "20:00"
    }
  ]
}
```

`day_of_week`: 0=周一, 1=周二, ..., 6=周日

### 排班详情
```
GET /api/v1/coach_schedules/:id
```

### 更新排班
```
PUT /api/v1/coach_schedules/:id
```

### 删除排班
```
DELETE /api/v1/coach_schedules/:id
```

### 可用排班列表
```
GET /api/v1/coach_schedules/available
```

查询参数：
- `coach_id`: 教练ID筛选
- `date`: 具体日期
- `week_date`: 周日期

## 课程预约 API

### 预约列表
```
GET /api/v1/bookings
```

查询参数：
- `member_id`: 会员ID筛选
- `coach_id`: 教练ID筛选
- `date`: 日期筛选
- `status`: 状态筛选
- `upcoming=true`: 仅显示即将到来的
- `past=true`: 仅显示历史

### 创建预约
```
POST /api/v1/bookings
```

请求体：
```json
{
  "booking": {
    "member_id": 1,
    "coach_schedule_id": 1
  }
}
```

### 预约详情
```
GET /api/v1/bookings/:id
```

### 取消预约
```
POST /api/v1/bookings/:id/cancel
```

**注意**: 必须在课程开始前至少2小时取消，否则会报 `cancellation_too_late` 错误。

### 强制取消预约（管理员）
```
POST /api/v1/bookings/:id/force_cancel
```

不受2小时限制，可退还次卡次数。

### 标记完成
```
POST /api/v1/bookings/:id/complete
```

### 标记未到
```
POST /api/v1/bookings/:id/mark_no_show
```

未到预约同样会消耗一次课时。

## 业务规则

### 卡类型

1. **次卡 (prepaid)**:
   - 按次数预约
   - 预约成功即扣减次数
   - 提前2小时取消可退还次数
   - 不足2小时取消或未到不退还

2. **月卡 (monthly)**:
   - 在有效期内可无限次预约
   - 预约成功不扣次数
   - 取消不涉及次数退还

### 预约规则

1. 会员状态必须为 `active`
2. 教练状态必须为 `active`
3. 排班状态必须为 `available`
4. 排班时段不能已约满
5. 不能预约过去的时段
6. 同一会员不能重复预约同一排班

### 取消规则

1. **正常取消**: 课程开始前2小时以上
   - 次卡会员：退还次数
   - 月卡会员：无影响

2. **逾期取消**: 不足2小时
   - 禁止取消，返回 `cancellation_too_late` 错误

3. **未到 (no_show)**:
   - 次卡会员：不退还次数
   - 月卡会员：无影响

### 排班规则

1. 同一教练同一时段只能有一个排班
2. 结束时间必须晚于开始时间
3. 不能创建过去日期的排班
4. 已有预约的排班不能删除

## 快速开始

### 启动服务

```bash
# 安装依赖
bundle install

# 创建数据库
rails db:create

# 运行迁移
rails db:migrate

# 导入种子数据
rails db:seed

# 启动服务
rails s
```

### 测试接口

```bash
# 1. 登录获取 Token
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.data.token')

# 2. 获取会员列表
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/members

# 3. 获取可用排班
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/coach_schedules/available

# 4. 创建预约
curl -X POST -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"booking":{"member_id":1,"coach_schedule_id":1}}' \
  http://localhost:3000/api/v1/bookings

# 5. 取消预约
curl -X POST -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/bookings/1/cancel
```
