#!/bin/bash

# ZenTask 停止脚本
# 优雅地停止所有后台服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
PID_DIR="$SCRIPT_DIR"
MAIN_PID_FILE="$PID_DIR/app.pid"
BACKEND_PID_FILE="$PID_DIR/backend.pid"
FRONTEND_PID_FILE="$PID_DIR/frontend.pid"

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

# 停止单个服务
stop_service() {
    local service_name=$1
    local pid_file=$2
    local timeout=${3:-10}
    
    local pid=$(read_pid "$pid_file")
    if is_process_running "$pid"; then
        log_info "正在停止${service_name} (PID: $pid)..."
        
        # 首先尝试优雅停止
        kill -TERM "$pid" 2>/dev/null
        
        # 等待进程停止
        local count=0
        while [ $count -lt $timeout ] && is_process_running "$pid"; do
            sleep 1
            count=$((count + 1))
        done
        
        # 如果还在运行，强制停止
        if is_process_running "$pid"; then
            log_warning "${service_name}未响应TERM信号，使用KILL信号强制停止..."
            kill -KILL "$pid" 2>/dev/null
            sleep 2
        fi
        
        if ! is_process_running "$pid"; then
            log_success "${service_name}已停止"
            cleanup_pid_file "$pid_file"
            return 0
        else
            log_error "${service_name}停止失败"
            return 1
        fi
    else
        log_info "${service_name}未运行"
        cleanup_pid_file "$pid_file"
        return 0
    fi
}

# 主停止函数
main() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║          ZenTask 停止脚本            ║"
    echo "║     正在停止所有服务...              ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    local stopped_any=false
    local all_success=true
    
    # 停止后端服务
    if stop_service "后端服务" "$BACKEND_PID_FILE" 15; then
        stopped_any=true
    else
        all_success=false
    fi
    
    # 停止前端服务
    if stop_service "前端服务" "$FRONTEND_PID_FILE" 10; then
        stopped_any=true
    else
        all_success=false
    fi
    
    # 清理主PID文件
    cleanup_pid_file "$MAIN_PID_FILE"
    
    # 记录停止日志
    if [ -d "$LOG_DIR" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] ZenTask 服务已停止" >> "$LOG_DIR/app.log"
    fi
    
    echo
    if [ "$stopped_any" = true ]; then
        if [ "$all_success" = true ]; then
            echo -e "${GREEN}"
            echo "╔══════════════════════════════════════╗"
            echo "║            ✅ 停止成功！             ║"
            echo "║        所有服务已安全停止            ║"
            echo "╚══════════════════════════════════════╝"
            echo -e "${NC}"
        else
            echo -e "${YELLOW}"
            echo "╔══════════════════════════════════════╗"
            echo "║            ⚠️  部分停止成功          ║"
            echo "║      部分服务可能需要手动处理        ║"
            echo "╚══════════════════════════════════════╝"
            echo -e "${NC}"
        fi
    else
        echo -e "${BLUE}"
        echo "╔══════════════════════════════════════╗"
        echo "║            ℹ️  没有运行的服务        ║"
        echo "║        所有服务都已停止              ║"
        echo "╚══════════════════════════════════════╝"
        echo -e "${NC}"
    fi
    
    # 提示如何重新启动
    echo
    log_info "重新启动服务："
    log_info "  前台模式: ./start.sh"
    log_info "  后台模式: ./start.sh --daemon"
}

# 运行主函数
main "$@"
