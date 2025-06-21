#!/bin/bash

# ZenTask 快速开发启动脚本 (Linux/macOS)
# 适用于已经配置好环境的开发者，快速启动前后端服务

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 清理函数
cleanup() {
    echo -e "\n${BLUE}[INFO]${NC} 正在停止服务..."
    
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} 服务已停止"
    exit 0
}

trap cleanup SIGINT SIGTERM

echo -e "${CYAN}"
echo "╔══════════════════════════════════════╗"
echo "║        ZenTask 快速开发启动          ║"
echo "║      (适用于已配置环境)              ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# 检查端口
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${BLUE}[ERROR]${NC} 端口 3000 被占用"
    exit 1
fi

if lsof -Pi :5173 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${BLUE}[ERROR]${NC} 端口 5173 被占用"
    exit 1
fi

# 启动后端
echo -e "${BLUE}[INFO]${NC} 启动后端服务..."
cd backend
npm run start:dev &
BACKEND_PID=$!
cd ..

# 启动前端
echo -e "${BLUE}[INFO]${NC} 启动前端服务..."
cd frontend
npm run dev &
FRONTEND_PID=$!
cd ..

# 等待服务启动
sleep 5

echo -e "${GREEN}"
echo "╔══════════════════════════════════════╗"
echo "║            🚀 启动完成！             ║"
echo "║  前端: http://localhost:5173         ║"
echo "║  后端: http://localhost:3000         ║"
echo "║  按 Ctrl+C 停止服务                  ║"
echo "╚══════════════════════════════════════╝"
echo -e "${NC}"

# 自动打开浏览器
if command -v open &> /dev/null; then
    open http://localhost:5173
elif command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:5173
fi

# 等待用户中断
wait
