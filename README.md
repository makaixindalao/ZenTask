# ZenTask - 极致简约的待办事项应用

## 项目概述

ZenTask 是一款基于 Web 的个人待办事项管理工具，旨在通过干净、美观且无干扰的界面，帮助用户高效地组织任务、跟踪进度并专注于最重要的事情。

## 技术栈

### 前端
- **框架**: Vue 3 (Composition API)
- **构建工具**: Vite
- **路由**: Vue Router
- **状态管理**: Pinia
- **HTTP请求**: Axios
- **UI框架**: Tailwind CSS
- **图标库**: Heroicons

### 后端
- **服务器框架**: NestJS
- **数据库**: MySQL 8.0+
- **ORM**: Prisma
- **认证**: JWT (JSON Web Tokens)

## 项目结构

```
zentask/
├── frontend/          # Vue3 前端应用
├── backend/           # NestJS 后端应用
├── doc/              # 项目文档
├── docker-compose.yml # Docker 容器编排
└── README.md         # 项目说明
```

## 快速开始

### 环境要求
- Node.js >= 18.0.0
- MySQL >= 8.0
- npm 或 yarn

### 安装依赖

```bash
# 安装前端依赖
cd frontend
npm install

# 安装后端依赖
cd ../backend
npm install
```

### 启动开发环境

```bash
# 启动后端服务 (端口: 3000)
cd backend
npm run start:dev

# 启动前端服务 (端口: 5173)
cd frontend
npm run dev
```

## 功能特性

- ✅ 用户注册/登录
- ✅ 多项目列表管理
- ✅ 任务CRUD操作
- ✅ 拖拽排序
- ✅ 智能视图（今天、最近7天）
- ✅ 响应式设计
- ✅ 深浅色主题切换
- ✅ 优雅的动画效果

## 开发计划

详细的开发计划请查看项目任务列表，包含19个主要开发阶段，从环境搭建到最终部署。

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。
