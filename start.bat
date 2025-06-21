@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ZenTask 一键启动脚本 (Windows)
REM 自动检查环境、安装依赖、启动数据库和前后端服务

title ZenTask 启动脚本

echo.
echo ╔══════════════════════════════════════╗
echo ║          ZenTask 启动脚本            ║
echo ║     极致简约的待办事项应用           ║
echo ╚══════════════════════════════════════╝
echo.

REM 颜色设置
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "PURPLE=[95m"
set "CYAN=[96m"
set "NC=[0m"

REM 检查 Node.js
echo %BLUE%[INFO]%NC% 检查系统环境...
node --version >nul 2>&1
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 请先安装 Node.js ^(^>= 18.0.0^)
    echo 下载地址: https://nodejs.org/
    pause
    exit /b 1
)

REM 检查 npm
npm --version >nul 2>&1
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 请先安装 npm
    pause
    exit /b 1
)

REM 获取 Node.js 版本
for /f "tokens=1 delims=." %%a in ('node --version') do (
    set "NODE_MAJOR=%%a"
    set "NODE_MAJOR=!NODE_MAJOR:v=!"
)

if !NODE_MAJOR! LSS 18 (
    echo %RED%[ERROR]%NC% Node.js 版本过低，需要 ^>= 18.0.0
    node --version
    pause
    exit /b 1
)

echo %GREEN%[SUCCESS]%NC% Node.js 版本检查通过
node --version
npm --version

REM 检查端口占用
echo %BLUE%[INFO]%NC% 检查端口占用...

netstat -an | findstr ":3000 " >nul 2>&1
if not errorlevel 1 (
    echo %RED%[ERROR]%NC% 后端端口 3000 被占用，请释放该端口
    pause
    exit /b 1
)

netstat -an | findstr ":5173 " >nul 2>&1
if not errorlevel 1 (
    echo %RED%[ERROR]%NC% 前端端口 5173 被占用，请释放该端口
    pause
    exit /b 1
)

echo %GREEN%[SUCCESS]%NC% 端口检查通过

REM 检查 Docker
set "USE_DOCKER_DB=false"
docker --version >nul 2>&1
if not errorlevel 1 (
    docker-compose --version >nul 2>&1
    if not errorlevel 1 (
        echo %BLUE%[INFO]%NC% 检测到 Docker，可以使用 Docker 启动 MySQL
        set /p "DOCKER_CHOICE=是否使用 Docker 启动 MySQL? (y/N): "
        if /i "!DOCKER_CHOICE!"=="y" (
            set "USE_DOCKER_DB=true"
        )
    )
)

if "!USE_DOCKER_DB!"=="false" (
    mysql --version >nul 2>&1
    if errorlevel 1 (
        echo %YELLOW%[WARNING]%NC% 未检测到 MySQL，请确保 MySQL 服务正在运行
        echo 或者安装 Docker 使用容器化数据库
    ) else (
        echo %GREEN%[SUCCESS]%NC% 检测到 MySQL
    )
)

REM 启动 Docker 数据库
if "!USE_DOCKER_DB!"=="true" (
    echo %PURPLE%[STEP]%NC% 启动 Docker 数据库...
    echo %BLUE%[INFO]%NC% 启动 MySQL 容器...
    docker-compose up -d mysql
    
    echo %BLUE%[INFO]%NC% 等待 MySQL 容器启动...
    timeout /t 10 /nobreak >nul
    
    REM 等待 MySQL 就绪
    set "MYSQL_READY=false"
    for /l %%i in (1,1,30) do (
        docker-compose exec -T mysql mysql -u zentask -pzentask123 -e "SELECT 1" >nul 2>&1
        if not errorlevel 1 (
            set "MYSQL_READY=true"
            goto :mysql_ready
        )
        echo 等待 MySQL 启动... %%i/30
        timeout /t 2 /nobreak >nul
    )
    
    :mysql_ready
    if "!MYSQL_READY!"=="false" (
        echo %RED%[ERROR]%NC% MySQL 容器启动超时
        pause
        exit /b 1
    )
    echo %GREEN%[SUCCESS]%NC% MySQL 容器已就绪
)

REM 安装后端依赖
echo %PURPLE%[STEP]%NC% 安装后端依赖...
cd backend

if not exist "node_modules" (
    echo %BLUE%[INFO]%NC% 安装后端依赖...
    call npm install
    if errorlevel 1 (
        echo %RED%[ERROR]%NC% 后端依赖安装失败
        pause
        exit /b 1
    )
    echo %GREEN%[SUCCESS]%NC% 后端依赖安装完成
) else (
    echo %BLUE%[INFO]%NC% 后端依赖已存在，跳过安装
)

REM 检查环境变量
if not exist ".env" (
    echo %BLUE%[INFO]%NC% 创建后端环境变量文件...
    copy .env.example .env >nul
    echo %YELLOW%[WARNING]%NC% 请编辑 backend\.env 文件配置数据库连接
    
    if "!USE_DOCKER_DB!"=="true" (
        REM 自动配置 Docker 数据库连接
        powershell -Command "(Get-Content .env) -replace 'DATABASE_URL=.*', 'DATABASE_URL=\"mysql://zentask:zentask123@localhost:3306/zentask\"' | Set-Content .env"
        echo %GREEN%[SUCCESS]%NC% 已自动配置 Docker 数据库连接
    )
)

REM 生成 Prisma 客户端
echo %BLUE%[INFO]%NC% 生成 Prisma 客户端...
call npx prisma generate
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Prisma 客户端生成失败
    pause
    exit /b 1
)

REM 运行数据库迁移
echo %BLUE%[INFO]%NC% 运行数据库迁移...
if "!USE_DOCKER_DB!"=="true" (
    call npx prisma db push
) else (
    call npx prisma migrate dev --name init
    if errorlevel 1 (
        call npx prisma db push
    )
)

if errorlevel 1 (
    echo %RED%[ERROR]%NC% 数据库迁移失败
    pause
    exit /b 1
)

echo %GREEN%[SUCCESS]%NC% 数据库配置完成

cd ..

REM 安装前端依赖
echo %PURPLE%[STEP]%NC% 安装前端依赖...
cd frontend

if not exist "node_modules" (
    echo %BLUE%[INFO]%NC% 安装前端依赖...
    call npm install
    if errorlevel 1 (
        echo %RED%[ERROR]%NC% 前端依赖安装失败
        pause
        exit /b 1
    )
    echo %GREEN%[SUCCESS]%NC% 前端依赖安装完成
) else (
    echo %BLUE%[INFO]%NC% 前端依赖已存在，跳过安装
)

cd ..

REM 启动服务
echo %PURPLE%[STEP]%NC% 启动应用服务...

echo %BLUE%[INFO]%NC% 启动后端服务...
cd backend
start "ZenTask Backend" cmd /c "npm run start:dev"
cd ..

REM 等待后端启动
echo %BLUE%[INFO]%NC% 等待后端服务启动...
timeout /t 8 /nobreak >nul

echo %BLUE%[INFO]%NC% 启动前端服务...
cd frontend
start "ZenTask Frontend" cmd /c "npm run dev"
cd ..

REM 等待前端启动
echo %BLUE%[INFO]%NC% 等待前端服务启动...
timeout /t 5 /nobreak >nul

REM 检查服务状态
echo %BLUE%[INFO]%NC% 检查服务状态...

REM 等待服务完全启动
for /l %%i in (1,1,15) do (
    curl -s http://localhost:3000 >nul 2>&1
    if not errorlevel 1 (
        goto :backend_ready
    )
    timeout /t 2 /nobreak >nul
)
echo %YELLOW%[WARNING]%NC% 后端服务可能未完全启动，请检查后端窗口

:backend_ready
for /l %%i in (1,1,15) do (
    curl -s http://localhost:5173 >nul 2>&1
    if not errorlevel 1 (
        goto :frontend_ready
    )
    timeout /t 2 /nobreak >nul
)
echo %YELLOW%[WARNING]%NC% 前端服务可能未完全启动，请检查前端窗口

:frontend_ready

REM 显示启动信息
echo.
echo %GREEN%╔══════════════════════════════════════╗%NC%
echo %GREEN%║            🎉 启动成功！             ║%NC%
echo %GREEN%╠══════════════════════════════════════╣%NC%
echo %GREEN%║  前端地址: http://localhost:5173     ║%NC%
echo %GREEN%║  后端地址: http://localhost:3000     ║%NC%
echo %GREEN%║  API文档:  http://localhost:3000/api ║%NC%
echo %GREEN%╠══════════════════════════════════════╣%NC%
echo %GREEN%║  关闭此窗口将停止所有服务            ║%NC%
echo %GREEN%╚══════════════════════════════════════╝%NC%
echo.

REM 自动打开浏览器
start http://localhost:5173

echo %BLUE%[INFO]%NC% 服务正在运行中...
echo %BLUE%[INFO]%NC% 前端和后端服务已在新窗口中启动
echo %BLUE%[INFO]%NC% 关闭此窗口或按任意键退出
echo.

pause

REM 清理
echo %BLUE%[INFO]%NC% 正在停止服务...
taskkill /f /im node.exe >nul 2>&1

if "!USE_DOCKER_DB!"=="true" (
    echo %BLUE%[INFO]%NC% 停止 Docker 数据库容器...
    docker-compose down >nul 2>&1
)

echo %GREEN%[SUCCESS]%NC% 清理完成
pause
