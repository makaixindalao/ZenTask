# ZenTask 启动脚本使用指南

本项目提供了多个便捷的启动脚本，帮助您快速启动和管理 ZenTask 应用。

## 📁 脚本文件说明

### 🚀 启动脚本

| 脚本文件 | 适用系统 | 功能描述 |
|---------|---------|----------|
| `start.sh` | Linux/macOS | 完整的一键启动脚本，包含环境检查和依赖安装 |
| `start.bat` | Windows | Windows 版本的一键启动脚本 |
| `dev.sh` | Linux/macOS | 快速开发启动脚本（适用于已配置环境） |

### 🛑 停止脚本

| 脚本文件 | 适用系统 | 功能描述 |
|---------|---------|----------|
| `stop.sh` | Linux/macOS | 优雅停止所有相关服务 |
| `stop.bat` | Windows | Windows 版本的停止脚本 |

## 🎯 使用方法

### Linux/macOS 用户

#### 首次启动（完整安装）
```bash
# 给脚本执行权限
chmod +x start.sh stop.sh dev.sh

# 运行完整启动脚本
./start.sh
```

#### 日常开发（快速启动）
```bash
# 适用于已经配置好环境的情况
./dev.sh
```

#### 停止服务
```bash
# 优雅停止所有服务
./stop.sh
```

### Windows 用户

#### 首次启动（完整安装）
```cmd
# 双击运行或在命令行中执行
start.bat
```

#### 停止服务
```cmd
# 双击运行或在命令行中执行
stop.bat
```

## ⚙️ 脚本功能详解

### 🔧 start.sh / start.bat（完整启动脚本）

**功能特性：**
- ✅ 自动检查系统环境（Node.js、npm、MySQL、Docker）
- ✅ 检查端口占用情况（3000、5173）
- ✅ 可选择使用 Docker 启动 MySQL 数据库
- ✅ 自动安装前后端依赖
- ✅ 自动配置环境变量文件
- ✅ 运行 Prisma 数据库迁移
- ✅ 并行启动前后端服务
- ✅ 自动打开浏览器
- ✅ 优雅的错误处理和用户提示

**适用场景：**
- 首次部署项目
- 全新环境配置
- 完整的环境检查

### ⚡ dev.sh（快速开发脚本）

**功能特性：**
- ✅ 快速启动前后端服务
- ✅ 基础的端口检查
- ✅ 自动打开浏览器
- ✅ 简洁的输出信息

**适用场景：**
- 日常开发工作
- 已配置好的开发环境
- 快速重启服务

### 🛑 stop.sh / stop.bat（停止脚本）

**功能特性：**
- ✅ 优雅停止前后端服务
- ✅ 停止相关的 Node.js 进程
- ✅ 停止 Docker 容器（如果使用）
- ✅ 清理临时文件
- ✅ 端口释放检查

## 🔍 环境要求

### 必需环境
- **Node.js**: >= 18.0.0
- **npm**: 最新版本
- **Git**: 用于版本控制

### 数据库选项
选择以下任一方式：

**选项1：Docker（推荐）**
- Docker
- Docker Compose

**选项2：本地 MySQL**
- MySQL >= 8.0
- 确保 MySQL 服务正在运行

## 🚨 故障排除

### 常见问题

#### 1. 端口被占用
```bash
# 查看端口占用
lsof -i :3000  # macOS/Linux
netstat -ano | findstr :3000  # Windows

# 杀死占用进程
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

#### 2. Node.js 版本过低
```bash
# 检查版本
node --version

# 升级 Node.js
# 访问 https://nodejs.org/ 下载最新版本
```

#### 3. 数据库连接失败
- 检查 MySQL 服务是否运行
- 验证 `backend/.env` 文件中的数据库配置
- 如果使用 Docker，确保容器正常启动

#### 4. 依赖安装失败
```bash
# 清理缓存重新安装
rm -rf node_modules package-lock.json
npm install
```

#### 5. 权限问题（Linux/macOS）
```bash
# 给脚本执行权限
chmod +x *.sh
```

### 手动启动方式

如果脚本无法正常工作，可以手动启动：

```bash
# 启动后端
cd backend
npm install
npx prisma generate
npx prisma db push
npm run start:dev

# 启动前端（新终端）
cd frontend
npm install
npm run dev
```

## 📝 自定义配置

### 修改端口
如需修改默认端口，请编辑以下文件：
- 后端端口：`backend/src/main.ts`
- 前端端口：`frontend/vite.config.ts`

### 数据库配置
编辑 `backend/.env` 文件：
```env
DATABASE_URL="mysql://username:password@localhost:3306/zentask"
```

## 🔄 更新项目

```bash
# 拉取最新代码
git pull origin main

# 重新运行启动脚本
./start.sh
```

## 💡 开发建议

1. **首次使用**：建议使用 `start.sh`/`start.bat` 进行完整配置
2. **日常开发**：使用 `dev.sh` 快速启动
3. **停止服务**：始终使用 `stop.sh`/`stop.bat` 优雅停止
4. **环境隔离**：建议使用 Docker 方式启动数据库

## 📞 获取帮助

如果遇到问题：
1. 查看脚本输出的错误信息
2. 检查 `backend/.env` 配置
3. 确认所有依赖已正确安装
4. 查看项目的 `deploy.md` 文档
