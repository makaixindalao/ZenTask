#!/bin/bash

# ZenTask 一键启动脚本 (Linux/macOS)
# 自动检查环境、安装依赖、启动数据库和前后端服务
# 支持前台和后台运行模式

set -e  # 遇到错误时退出

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
PID_DIR="$SCRIPT_DIR"
MAIN_PID_FILE="$PID_DIR/app.pid"
BACKEND_PID_FILE="$PID_DIR/backend.pid"
FRONTEND_PID_FILE="$PID_DIR/frontend.pid"
DAEMON_MODE=false
STOP_MODE=false
STATUS_MODE=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# 创建必要的目录
create_directories() {
    mkdir -p "$LOG_DIR"
    log_info "日志目录已创建: $LOG_DIR"
}

# 写入PID文件
write_pid() {
    local pid=$1
    local pid_file=$2
    echo "$pid" > "$pid_file"
    log_info "PID $pid 已写入 $pid_file"
}

# 读取PID文件
read_pid() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        cat "$pid_file"
    else
        echo ""
    fi
}

# 检查进程是否运行
is_process_running() {
    local pid=$1
    if [ -z "$pid" ]; then
        return 1
    fi
    if kill -0 "$pid" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 清理PID文件
cleanup_pid_file() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        rm -f "$pid_file"
        log_info "已清理PID文件: $pid_file"
    fi
}

# 获取服务状态
get_service_status() {
    local service_name=$1
    local pid_file=$2
    local port=$3

    local pid=$(read_pid "$pid_file")
    if is_process_running "$pid"; then
        if [ -n "$port" ] && curl -s "http://localhost:$port" >/dev/null 2>&1; then
            echo "运行中 (PID: $pid, 端口: $port)"
        else
            echo "运行中 (PID: $pid)"
        fi
    else
        cleanup_pid_file "$pid_file"
        echo "未运行"
    fi
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 未安装，请先安装 $1"
        return 1
    fi
    return 0
}

# 检查端口是否被占用
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "端口 $1 已被占用"
        return 1
    fi
    return 0
}

# 检查MySQL服务是否已在运行
check_mysql_running() {
    local port=${1:-3306}

    # 检查端口是否被占用
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_info "检测到端口 $port 已被占用，正在验证是否为MySQL服务..."

        # 尝试连接MySQL服务
        if command -v mysql &> /dev/null; then
            # 尝试使用默认连接参数连接
            if mysql -h localhost -P $port -u root --connect-timeout=5 -e "SELECT 1" >/dev/null 2>&1; then
                log_success "检测到MySQL服务正在端口 $port 运行 (root用户)"
                return 0
            fi

            # 尝试使用项目配置的用户连接
            if mysql -h localhost -P $port -u zentask -pzentask123 --connect-timeout=5 -e "SELECT 1" >/dev/null 2>&1; then
                log_success "检测到MySQL服务正在端口 $port 运行 (zentask用户)"
                return 0
            fi
        fi

        # 使用netcat或telnet检查端口响应
        if command -v nc &> /dev/null; then
            if echo "quit" | nc -w 3 localhost $port >/dev/null 2>&1; then
                log_success "检测到端口 $port 有服务响应，假设为MySQL服务"
                return 0
            fi
        elif command -v telnet &> /dev/null; then
            if timeout 3 telnet localhost $port >/dev/null 2>&1; then
                log_success "检测到端口 $port 有服务响应，假设为MySQL服务"
                return 0
            fi
        fi

        log_warning "端口 $port 被占用但无法确认是否为MySQL服务"
        return 1
    fi

    return 1
}

# 等待服务启动
wait_for_service() {
    local port=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    log_info "等待 $service_name 启动 (端口 $port)..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:$port >/dev/null 2>&1; then
            log_success "$service_name 已启动 (端口 $port)"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_error "$service_name 启动超时"
    return 1
}

# 清理函数
cleanup() {
    if [ "$DAEMON_MODE" = true ]; then
        # 后台模式下不进行清理，让进程继续运行
        return
    fi

    log_info "正在清理进程..."

    # 杀死后台进程
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
        log_info "后端服务已停止"
    fi

    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
        log_info "前端服务已停止"
    fi

    # 停止 Docker 容器（仅当使用Docker数据库时）
    if [ "$USE_DOCKER_DB" = true ]; then
        log_info "停止 Docker 数据库容器..."
        docker-compose down >/dev/null 2>&1 || true
    elif [ "$USE_EXISTING_MYSQL" = true ]; then
        log_info "保留已存在的MySQL服务运行"
    fi

    # 清理PID文件
    cleanup_pid_file "$BACKEND_PID_FILE"
    cleanup_pid_file "$FRONTEND_PID_FILE"
    cleanup_pid_file "$MAIN_PID_FILE"

    log_success "清理完成"
    exit 0
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--daemon)
                DAEMON_MODE=true
                shift
                ;;
            --stop)
                STOP_MODE=true
                shift
                ;;
            --status)
                STATUS_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║          ZenTask 启动脚本            ║"
    echo "║     极致简约的待办事项应用           ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    echo "用法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -d, --daemon    后台运行模式"
    echo "  --stop          停止后台服务"
    echo "  --status        查看服务状态"
    echo "  -h, --help      显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0              # 前台运行（默认）"
    echo "  $0 --daemon     # 后台运行"
    echo "  $0 --stop       # 停止后台服务"
    echo "  $0 --status     # 查看服务状态"
    echo
}

# 显示服务状态
show_status() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║            服务状态                  ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"

    echo "后端服务: $(get_service_status "后端" "$BACKEND_PID_FILE" "3000")"
    echo "前端服务: $(get_service_status "前端" "$FRONTEND_PID_FILE" "5173")"

    # 检查数据库状态
    if check_mysql_running 3306; then
        echo "数据库服务: 运行中 (端口: 3306)"
    else
        echo "数据库服务: 未运行"
    fi

    echo
    echo "日志文件位置:"
    echo "  主日志: $LOG_DIR/app.log"
    echo "  后端日志: $LOG_DIR/backend.log"
    echo "  前端日志: $LOG_DIR/frontend.log"
}

# 停止所有服务
stop_services() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║            停止服务                  ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"

    local stopped_any=false

    # 停止后端服务
    local backend_pid=$(read_pid "$BACKEND_PID_FILE")
    if is_process_running "$backend_pid"; then
        log_info "正在停止后端服务 (PID: $backend_pid)..."
        kill -TERM "$backend_pid" 2>/dev/null || kill -KILL "$backend_pid" 2>/dev/null
        sleep 2
        if ! is_process_running "$backend_pid"; then
            log_success "后端服务已停止"
            stopped_any=true
        else
            log_warning "后端服务停止失败"
        fi
        cleanup_pid_file "$BACKEND_PID_FILE"
    else
        log_info "后端服务未运行"
    fi

    # 停止前端服务
    local frontend_pid=$(read_pid "$FRONTEND_PID_FILE")
    if is_process_running "$frontend_pid"; then
        log_info "正在停止前端服务 (PID: $frontend_pid)..."
        kill -TERM "$frontend_pid" 2>/dev/null || kill -KILL "$frontend_pid" 2>/dev/null
        sleep 2
        if ! is_process_running "$frontend_pid"; then
            log_success "前端服务已停止"
            stopped_any=true
        else
            log_warning "前端服务停止失败"
        fi
        cleanup_pid_file "$FRONTEND_PID_FILE"
    else
        log_info "前端服务未运行"
    fi

    # 清理主PID文件
    cleanup_pid_file "$MAIN_PID_FILE"

    if [ "$stopped_any" = true ]; then
        log_success "服务停止完成"
    else
        log_info "没有运行中的服务需要停止"
    fi
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 主函数
main() {
    # 解析命令行参数
    parse_arguments "$@"

    # 处理特殊模式
    if [ "$STATUS_MODE" = true ]; then
        show_status
        exit 0
    fi

    if [ "$STOP_MODE" = true ]; then
        stop_services
        exit 0
    fi

    # 创建必要目录
    create_directories

    # 检查是否已有服务在运行
    local backend_pid=$(read_pid "$BACKEND_PID_FILE")
    local frontend_pid=$(read_pid "$FRONTEND_PID_FILE")

    if is_process_running "$backend_pid" || is_process_running "$frontend_pid"; then
        log_warning "检测到服务已在运行："
        if is_process_running "$backend_pid"; then
            log_warning "  后端服务 (PID: $backend_pid)"
        fi
        if is_process_running "$frontend_pid"; then
            log_warning "  前端服务 (PID: $frontend_pid)"
        fi
        log_error "请先停止现有服务: $0 --stop"
        exit 1
    fi

    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║          ZenTask 启动脚本            ║"
    echo "║     极致简约的待办事项应用           ║"
    if [ "$DAEMON_MODE" = true ]; then
        echo "║           (后台运行模式)             ║"
    else
        echo "║           (前台运行模式)             ║"
    fi
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 检查必要的命令
    log_step "1. 检查系统环境"
    
    if ! check_command "node"; then
        log_error "请先安装 Node.js (>= 18.0.0)"
        exit 1
    fi
    
    if ! check_command "npm"; then
        log_error "请先安装 npm"
        exit 1
    fi
    
    # 检查 Node.js 版本
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        log_error "Node.js 版本过低，需要 >= 18.0.0，当前版本: $(node -v)"
        exit 1
    fi
    
    log_success "Node.js 版本: $(node -v)"
    log_success "npm 版本: $(npm -v)"
    
    # 检查数据库配置
    log_step "2. 检查数据库配置"

    USE_DOCKER_DB=false
    USE_EXISTING_MYSQL=false

    # 首先检查是否已有MySQL服务在运行
    if check_mysql_running 3306; then
        log_success "检测到MySQL服务已在3306端口运行"
        USE_EXISTING_MYSQL=true

        # 询问用户是否使用已存在的MySQL服务
        # read -p "是否使用已存在的MySQL服务? (Y/n): " -n 1 -r
        # echo
        # if [[ $REPLY =~ ^[Nn]$ ]]; then
        #     log_error "请先停止现有的MySQL服务，或使用不同的端口"
        #     exit 1
        # fi

        log_info "将使用已存在的MySQL服务"
    else
        # 没有检测到MySQL服务，询问是否使用Docker
        if check_command "docker" && check_command "docker-compose"; then
            log_info "检测到 Docker，可以使用 Docker 启动 MySQL"
            read -p "是否使用 Docker 启动 MySQL? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                USE_DOCKER_DB=true
            fi
        fi

        if [ "$USE_DOCKER_DB" = false ] && [ "$USE_EXISTING_MYSQL" = false ]; then
            if ! check_command "mysql"; then
                log_warning "未检测到 MySQL，请确保 MySQL 服务正在运行"
                log_info "或者安装 Docker 使用容器化数据库"
            else
                log_success "检测到 MySQL 客户端"
            fi
        fi
    fi
    
    # 检查端口
    log_step "3. 检查端口占用"
    
    if ! check_port 3000; then
        log_error "后端端口 3000 被占用，请释放该端口"
        exit 1
    fi
    
    if ! check_port 5173; then
        log_error "前端端口 5173 被占用，请释放该端口"
        exit 1
    fi
    
    log_success "端口检查通过"
    
    # 启动数据库
    if [ "$USE_EXISTING_MYSQL" = true ]; then
        log_step "4. 使用已存在的MySQL服务"
        log_success "跳过MySQL容器启动，使用已存在的MySQL服务 (端口3306)"

        # 验证数据库连接和数据库是否存在
        log_info "验证数据库连接..."
        if command -v mysql &> /dev/null; then
            # 尝试创建数据库（如果不存在）
            mysql -h localhost -P 3306 -u root -e "CREATE DATABASE IF NOT EXISTS zentask;" 2>/dev/null || \
            mysql -h localhost -P 3306 -u zentask -pzentask123 -e "SELECT 1;" 2>/dev/null || {
                log_warning "无法连接到MySQL服务，请确保数据库配置正确"
                log_info "请手动创建数据库 'zentask' 或配置正确的数据库连接"
            }
        fi

    elif [ "$USE_DOCKER_DB" = true ]; then
        log_step "4. 启动 Docker 数据库"

        log_info "启动 MySQL 容器..."
        docker-compose up -d mysql

        log_info "等待 MySQL 容器启动..."
        sleep 10

        # 等待 MySQL 就绪
        local attempt=1
        while [ $attempt -le 30 ]; do
            if docker-compose exec -T mysql mysql -u zentask -pzentask123 -e "SELECT 1" >/dev/null 2>&1; then
                log_success "MySQL 容器已就绪"
                break
            fi
            echo -n "."
            sleep 2
            attempt=$((attempt + 1))
        done

        if [ $attempt -gt 30 ]; then
            log_error "MySQL 容器启动超时"
            exit 1
        fi
    else
        log_step "4. 使用本地MySQL服务"
        log_info "假设MySQL服务已在本地运行，跳过数据库启动"
    fi
    
    # 安装后端依赖
    log_step "5. 安装后端依赖"
    
    cd backend
    
    if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
        log_info "安装后端依赖..."
        npm install
        log_success "后端依赖安装完成"
    else
        log_info "后端依赖已存在，跳过安装"
    fi
    
    # 检查环境变量
    if [ ! -f ".env" ]; then
        log_info "创建后端环境变量文件..."
        cp .env.example .env
        log_warning "请编辑 backend/.env 文件配置数据库连接"

        if [ "$USE_DOCKER_DB" = true ]; then
            # 自动配置 Docker 数据库连接（使用3306端口）
            sed -i.bak 's|DATABASE_URL=.*|DATABASE_URL="mysql://zentask:zentask123@localhost:3306/zentask"|' .env
            log_success "已自动配置 Docker 数据库连接（端口3306）"
        elif [ "$USE_EXISTING_MYSQL" = true ]; then
            # 自动配置已存在的MySQL连接
            sed -i.bak 's|DATABASE_URL=.*|DATABASE_URL="mysql://zentask:zentask123@localhost:3306/zentask"|' .env
            log_success "已自动配置现有MySQL数据库连接（端口3306）"
            log_info "如果连接失败，请手动编辑 backend/.env 文件配置正确的数据库用户名和密码"
        fi
    fi
    
    # 生成 Prisma 客户端
    log_info "生成 Prisma 客户端..."
    npx prisma generate
    
    # 运行数据库迁移
    log_info "运行数据库迁移..."
    if [ "$USE_DOCKER_DB" = true ]; then
        npx prisma db push
    else
        # 先测试数据库连接
        if ! npx prisma db push 2>/dev/null; then
            log_warning "数据库连接失败，可能需要创建zentask用户"
            log_info "尝试自动修复MySQL认证问题..."

            # 检查是否有Docker MySQL容器
            if command -v docker &> /dev/null; then
                local container_name=$(docker ps --filter "publish=3306" --format "{{.Names}}" | head -1)
                if [ ! -z "$container_name" ]; then
                    log_info "检测到MySQL容器: $container_name，尝试创建zentask用户..."
                    local root_password=$(docker inspect "$container_name" | grep "MYSQL_ROOT_PASSWORD" | cut -d'=' -f2 | tr -d '",' | head -1)

                    if [ ! -z "$root_password" ]; then
                        local sql_commands="
CREATE DATABASE IF NOT EXISTS zentask CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'zentask'@'localhost' IDENTIFIED BY 'zentask123';
CREATE USER IF NOT EXISTS 'zentask'@'%' IDENTIFIED BY 'zentask123';
GRANT ALL PRIVILEGES ON zentask.* TO 'zentask'@'localhost';
GRANT ALL PRIVILEGES ON zentask.* TO 'zentask'@'%';
FLUSH PRIVILEGES;
"
                        if echo "$sql_commands" | docker exec -i "$container_name" mysql -u root -p"$root_password" >/dev/null 2>&1; then
                            log_success "zentask用户创建成功，重新尝试数据库迁移..."
                            npx prisma db push
                        else
                            log_error "自动修复失败，请手动运行: ./fix-mysql-auth.sh"
                            exit 1
                        fi
                    else
                        log_error "无法获取MySQL root密码，请手动运行: ./fix-mysql-auth.sh"
                        exit 1
                    fi
                else
                    log_error "数据库连接失败，请检查MySQL配置或运行: ./fix-mysql-auth.sh"
                    exit 1
                fi
            else
                log_error "数据库连接失败，请检查MySQL配置或运行: ./fix-mysql-auth.sh"
                exit 1
            fi
        fi
    fi
    
    log_success "数据库配置完成"
    
    cd ..
    
    # 安装前端依赖
    log_step "6. 安装前端依赖"
    
    cd frontend
    
    if [ ! -d "node_modules" ] || [ ! -f "package-lock.json" ]; then
        log_info "安装前端依赖..."
        npm install
        log_success "前端依赖安装完成"
    else
        log_info "前端依赖已存在，跳过安装"
    fi
    
    cd ..
    
    # 启动服务
    log_step "7. 启动应用服务"

    if [ "$DAEMON_MODE" = true ]; then
        # 后台模式启动
        log_info "以后台模式启动服务..."

        # 启动后端服务
        log_info "启动后端服务..."
        cd backend
        nohup npm run start:dev > "$LOG_DIR/backend.log" 2>&1 &
        BACKEND_PID=$!
        write_pid "$BACKEND_PID" "$BACKEND_PID_FILE"
        cd ..

        # 等待后端启动
        sleep 5

        # 启动前端服务
        log_info "启动前端服务..."
        cd frontend
        nohup npm run dev > "$LOG_DIR/frontend.log" 2>&1 &
        FRONTEND_PID=$!
        write_pid "$FRONTEND_PID" "$FRONTEND_PID_FILE"
        cd ..

        # 写入主进程PID
        write_pid "$$" "$MAIN_PID_FILE"

    else
        # 前台模式启动
        log_info "以前台模式启动服务..."

        # 启动后端服务
        log_info "启动后端服务..."
        cd backend
        npm run start:dev &
        BACKEND_PID=$!
        cd ..

        # 等待后端启动
        sleep 5

        # 启动前端服务
        log_info "启动前端服务..."
        cd frontend
        npm run dev &
        FRONTEND_PID=$!
        cd ..
    fi

    # 等待服务启动
    wait_for_service 3000 "后端服务"
    wait_for_service 5173 "前端服务"
    
    # 显示启动信息
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════╗"
    echo "║            🎉 启动成功！             ║"
    echo "╠══════════════════════════════════════╣"
    echo "║  前端地址: http://localhost:5173     ║"
    echo "║  后端地址: http://localhost:3000     ║"
    echo "║  API文档:  http://localhost:3000/api ║"
    echo "╠══════════════════════════════════════╣"
    if [ "$DAEMON_MODE" = true ]; then
        echo "║  后台运行模式已启动                  ║"
        echo "║  使用 $0 --stop 停止服务    ║"
        echo "║  使用 $0 --status 查看状态  ║"
    else
        echo "║  按 Ctrl+C 停止所有服务              ║"
    fi
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"

    if [ "$DAEMON_MODE" = true ]; then
        # 后台模式信息
        echo
        log_success "服务已在后台启动"
        log_info "日志文件位置:"
        log_info "  主日志: $LOG_DIR/app.log"
        log_info "  后端日志: $LOG_DIR/backend.log"
        log_info "  前端日志: $LOG_DIR/frontend.log"
        echo
        log_info "管理命令:"
        log_info "  查看状态: $0 --status"
        log_info "  停止服务: $0 --stop"
        log_info "  查看日志: tail -f $LOG_DIR/app.log"

        # 将启动信息写入日志
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] ZenTask 服务已启动"
            echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] 前端地址: http://localhost:5173"
            echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] 后端地址: http://localhost:3000"
            echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] 后端PID: $BACKEND_PID"
            echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] 前端PID: $FRONTEND_PID"
        } >> "$LOG_DIR/app.log"

    else
        # 前台模式
        # 自动打开浏览器
        if command -v open &> /dev/null; then
            open http://localhost:5173
        elif command -v xdg-open &> /dev/null; then
            xdg-open http://localhost:5173
        fi

        # 等待用户中断
        log_info "服务正在运行中，按 Ctrl+C 停止..."
        wait
    fi
}

# 运行主函数
main "$@"
