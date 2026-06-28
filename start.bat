@echo off
echo ========================================
echo  私教健身工作室会员管理系统 API
echo ========================================
echo.

echo [1/4] 检查 PostgreSQL 服务...
sc query postgresql-x64-15 | findstr "RUNNING" >nul
if errorlevel 1 (
    echo 正在启动 PostgreSQL 服务...
    net start postgresql-x64-15
    if errorlevel 1 (
        echo 警告: 无法启动 PostgreSQL 服务，请手动启动
        pause
        exit /b 1
    )
)
echo PostgreSQL 服务已启动
echo.

echo [2/4] 安装依赖...
bundle install
echo.

echo [3/4] 数据库迁移...
rails db:create
rails db:migrate
rails db:seed
echo.

echo [4/4] 启动 Rails 服务器...
echo.
echo 服务地址: http://localhost:3000
echo API 文档: API_DOC.md
echo 默认账号: admin / admin123
echo.
rails s
