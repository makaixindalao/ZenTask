#!/bin/bash

# ZenTask 一键启动脚本 (Linux/macOS)
# 自动检查环境、安装依赖、启动数据库和前后端服务

set -e  # 遇到错误时退出

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
    
    # 停止 Docker 容器
    if [ "$USE_DOCKER_DB" = true ]; then
        log_info "停止 Docker 数据库容器..."
        docker-compose down >/dev/null 2>&1 || true
    fi
    
    log_success "清理完成"
    exit 0
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 主函数
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║          ZenTask 启动脚本            ║"
    echo "║     极致简约的待办事项应用           ║"
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
    
    # 检查数据库选项
    log_step "2. 检查数据库配置"
    
    USE_DOCKER_DB=false
    if check_command "docker" && check_command "docker-compose"; then
        log_info "检测到 Docker，可以使用 Docker 启动 MySQL"
        read -p "是否使用 Docker 启动 MySQL? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            USE_DOCKER_DB=true
        fi
    fi
    
    if [ "$USE_DOCKER_DB" = false ]; then
        if ! check_command "mysql"; then
            log_warning "未检测到 MySQL，请确保 MySQL 服务正在运行"
            log_info "或者安装 Docker 使用容器化数据库"
        else
            log_success "检测到 MySQL"
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
    if [ "$USE_DOCKER_DB" = true ]; then
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
            # 自动配置 Docker 数据库连接
            sed -i.bak 's|DATABASE_URL=.*|DATABASE_URL="mysql://zentask:zentask123@localhost:3306/zentask"|' .env
            log_success "已自动配置 Docker 数据库连接"
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
        npx prisma migrate dev --name init || npx prisma db push
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
    
    log_info "启动后端服务..."
    cd backend
    npm run start:dev &
    BACKEND_PID=$!
    cd ..
    
    # 等待后端启动
    sleep 5
    
    log_info "启动前端服务..."
    cd frontend
    npm run dev &
    FRONTEND_PID=$!
    cd ..
    
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
    echo "║  按 Ctrl+C 停止所有服务              ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 自动打开浏览器
    if command -v open &> /dev/null; then
        open http://localhost:5173
    elif command -v xdg-open &> /dev/null; then
        xdg-open http://localhost:5173
    fi
    
    # 等待用户中断
    log_info "服务正在运行中，按 Ctrl+C 停止..."
    wait
}

# 运行主函数
main "$@"
