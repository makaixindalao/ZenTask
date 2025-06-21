@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ZenTask 停止脚本 (Windows)
REM 优雅地停止所有相关服务

title ZenTask 停止脚本

echo.
echo ╔══════════════════════════════════════╗
echo ║          ZenTask 停止脚本            ║
echo ║       优雅停止所有相关服务           ║
echo ╚══════════════════════════════════════╝
echo.

REM 颜色设置
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "CYAN=[96m"
set "NC=[0m"

echo %BLUE%[INFO]%NC% 开始停止 ZenTask 相关服务...

REM 停止前端服务 (端口 5173)
echo %BLUE%[INFO]%NC% 停止前端服务 (端口 5173)...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":5173 "') do (
    set "PID=%%a"
    if defined PID (
        taskkill /PID !PID! /F >nul 2>&1
        if not errorlevel 1 (
            echo %GREEN%[SUCCESS]%NC% 前端服务已停止 (PID: !PID!)
        )
    )
)

REM 停止后端服务 (端口 3000)
echo %BLUE%[INFO]%NC% 停止后端服务 (端口 3000)...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000 "') do (
    set "PID=%%a"
    if defined PID (
        taskkill /PID !PID! /F >nul 2>&1
        if not errorlevel 1 (
            echo %GREEN%[SUCCESS]%NC% 后端服务已停止 (PID: !PID!)
        )
    )
)

REM 停止所有 Node.js 进程 (谨慎操作)
echo %BLUE%[INFO]%NC% 查找并停止 ZenTask 相关的 Node.js 进程...

REM 查找包含特定命令行参数的 node.exe 进程
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq node.exe" /FO CSV ^| findstr /C:"npm" 2^>nul') do (
    set "PID=%%a"
    set "PID=!PID:"=!"
    if defined PID (
        taskkill /PID !PID! /F >nul 2>&1
        if not errorlevel 1 (
            echo %GREEN%[SUCCESS]%NC% Node.js 进程已停止 (PID: !PID!)
        )
    )
)

REM 停止可能的 npm 进程
echo %BLUE%[INFO]%NC% 停止 npm 相关进程...
taskkill /IM npm.exe /F >nul 2>&1
if not errorlevel 1 (
    echo %GREEN%[SUCCESS]%NC% npm 进程已停止
)

REM 停止可能的 cmd 窗口 (ZenTask 相关)
echo %BLUE%[INFO]%NC% 停止 ZenTask 相关的命令行窗口...
for /f "tokens=2" %%a in ('tasklist /FI "WINDOWTITLE eq ZenTask*" /FO CSV 2^>nul ^| findstr /C:"cmd.exe"') do (
    set "PID=%%a"
    set "PID=!PID:"=!"
    if defined PID (
        taskkill /PID !PID! /F >nul 2>&1
        if not errorlevel 1 (
            echo %GREEN%[SUCCESS]%NC% ZenTask 窗口已关闭 (PID: !PID!)
        )
    )
)

REM 停止 Docker 容器
echo %BLUE%[INFO]%NC% 检查并停止 Docker 容器...
docker --version >nul 2>&1
if not errorlevel 1 (
    docker-compose --version >nul 2>&1
    if not errorlevel 1 (
        if exist "docker-compose.yml" (
            echo %BLUE%[INFO]%NC% 停止 Docker 容器...
            docker-compose down >nul 2>&1
            if not errorlevel 1 (
                echo %GREEN%[SUCCESS]%NC% Docker 容器已停止
            ) else (
                echo %YELLOW%[WARNING]%NC% 停止 Docker 容器时出现问题
            )
        ) else (
            echo %BLUE%[INFO]%NC% 未找到 docker-compose.yml 文件
        )
    ) else (
        echo %BLUE%[INFO]%NC% Docker Compose 未安装，跳过容器停止
    )
) else (
    echo %BLUE%[INFO]%NC% Docker 未安装，跳过容器停止
)

REM 清理临时文件
echo %BLUE%[INFO]%NC% 清理临时文件...

REM 删除可能的 PID 文件
for /r %%f in (*.pid) do (
    del "%%f" >nul 2>&1
)

REM 清理 npm 缓存锁文件
if exist "backend\package-lock.json.lock" (
    del "backend\package-lock.json.lock" >nul 2>&1
)

if exist "frontend\package-lock.json.lock" (
    del "frontend\package-lock.json.lock" >nul 2>&1
)

echo %GREEN%[SUCCESS]%NC% 临时文件清理完成

REM 等待一下确保所有进程都已停止
timeout /t 2 /nobreak >nul

REM 最终检查
echo %BLUE%[INFO]%NC% 最终检查服务状态...

set "SERVICES_RUNNING=false"

netstat -an | findstr ":3000 " >nul 2>&1
if not errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% 端口 3000 仍被占用
    set "SERVICES_RUNNING=true"
)

netstat -an | findstr ":5173 " >nul 2>&1
if not errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% 端口 5173 仍被占用
    set "SERVICES_RUNNING=true"
)

if "!SERVICES_RUNNING!"=="false" (
    echo %GREEN%[SUCCESS]%NC% 所有服务端口已释放
)

echo.
echo %GREEN%╔══════════════════════════════════════╗%NC%
echo %GREEN%║            🛑 停止完成！             ║%NC%
echo %GREEN%║        所有服务已安全停止            ║%NC%
echo %GREEN%╚══════════════════════════════════════╝%NC%
echo.

if "!SERVICES_RUNNING!"=="true" (
    echo %YELLOW%[WARNING]%NC% 部分服务可能仍在运行，请手动检查
    echo %BLUE%[INFO]%NC% 您可以重启计算机以确保完全清理
    echo.
)

echo 按任意键退出...
pause >nul
