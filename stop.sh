#!/bin/bash

# ZenTask 停止脚本 (Linux/macOS)
# 优雅地停止所有相关服务

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 停止进程函数
stop_process() {
    local process_name=$1
    local port=$2
    
    # 通过端口查找进程
    local pids=$(lsof -ti:$port 2>/dev/null)
    
    if [ ! -z "$pids" ]; then
        log_info "停止 $process_name (端口 $port)..."
        echo "$pids" | xargs kill -TERM 2>/dev/null
        
        # 等待进程优雅退出
        sleep 3
        
        # 检查是否还有进程在运行
        local remaining_pids=$(lsof -ti:$port 2>/dev/null)
        if [ ! -z "$remaining_pids" ]; then
            log_warning "$process_name 未能优雅退出，强制终止..."
            echo "$remaining_pids" | xargs kill -KILL 2>/dev/null
        fi
        
        log_success "$process_name 已停止"
    else
        log_info "$process_name 未在运行"
    fi
}

# 停止 Node.js 进程
stop_node_processes() {
    log_info "查找并停止 ZenTask 相关的 Node.js 进程..."
    
    # 查找包含 zentask 或相关路径的 node 进程
    local node_pids=$(ps aux | grep -E "(node.*zentask|npm.*start|vite|nest)" | grep -v grep | awk '{print $2}')
    
    if [ ! -z "$node_pids" ]; then
        log_info "发现 ZenTask 相关进程，正在停止..."
        echo "$node_pids" | xargs kill -TERM 2>/dev/null
        
        # 等待进程退出
        sleep 3
        
        # 检查是否还有进程
        local remaining_pids=$(ps aux | grep -E "(node.*zentask|npm.*start|vite|nest)" | grep -v grep | awk '{print $2}')
        if [ ! -z "$remaining_pids" ]; then
            log_warning "部分进程未能优雅退出，强制终止..."
            echo "$remaining_pids" | xargs kill -KILL 2>/dev/null
        fi
        
        log_success "Node.js 进程已停止"
    else
        log_info "未发现 ZenTask 相关的 Node.js 进程"
    fi
}

# 停止 Docker 容器
stop_docker_containers() {
    if command -v docker-compose &> /dev/null; then
        if [ -f "docker-compose.yml" ]; then
            log_info "停止 Docker 容器..."
            docker-compose down 2>/dev/null
            
            if [ $? -eq 0 ]; then
                log_success "Docker 容器已停止"
            else
                log_warning "停止 Docker 容器时出现问题"
            fi
        else
            log_info "未找到 docker-compose.yml 文件"
        fi
    else
        log_info "Docker Compose 未安装，跳过容器停止"
    fi
}

# 清理临时文件
cleanup_temp_files() {
    log_info "清理临时文件..."
    
    # 清理可能的 PID 文件
    find . -name "*.pid" -type f -delete 2>/dev/null
    
    # 清理日志文件（可选）
    # find . -name "*.log" -type f -delete 2>/dev/null
    
    log_success "临时文件清理完成"
}

# 主函数
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║          ZenTask 停止脚本            ║"
    echo "║       优雅停止所有相关服务           ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 停止前端服务 (端口 5173)
    stop_process "前端服务" 5173
    
    # 停止后端服务 (端口 3000)
    stop_process "后端服务" 3000
    
    # 停止其他可能的 Node.js 进程
    stop_node_processes
    
    # 停止 Docker 容器
    stop_docker_containers
    
    # 清理临时文件
    cleanup_temp_files
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════╗"
    echo "║            🛑 停止完成！             ║"
    echo "║        所有服务已安全停止            ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# 运行主函数
main "$@"
