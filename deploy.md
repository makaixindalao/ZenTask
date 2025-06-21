# ZenTask 部署指南

## 环境要求

### 系统要求
- Node.js >= 18.0.0
- MySQL >= 8.0
- Docker (可选)
- Nginx (生产环境推荐)

### 开发环境
- npm 或 yarn
- Git

## 本地开发部署

### 1. 克隆项目
```bash
git clone <repository-url>
cd zentask
```

### 2. 安装依赖
```bash
# 安装前端依赖
cd frontend
npm install

# 安装后端依赖
cd ../backend
npm install
```

### 3. 配置环境变量
```bash
# 复制环境变量模板
cd backend
cp .env.example .env

# 编辑环境变量
nano .env
```

### 4. 数据库设置
```bash
# 创建数据库
mysql -u root -p
CREATE DATABASE zentask;

# 运行数据库迁移
cd backend
npx prisma migrate dev
npx prisma generate
```

### 5. 启动服务
```bash
# 启动后端服务
cd backend
npm run start:dev

# 启动前端服务
cd frontend
npm run dev
```

## Docker 部署

### 1. 使用 Docker Compose
```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 2. 单独构建镜像
```bash
# 构建后端镜像
cd backend
docker build -t zentask-backend .

# 构建前端镜像
cd frontend
docker build -t zentask-frontend .
```

## 生产环境部署

### 1. 服务器准备
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装 MySQL
sudo apt install mysql-server -y

# 安装 Nginx
sudo apt install nginx -y

# 安装 PM2
sudo npm install -g pm2
```

### 2. 部署后端
```bash
# 克隆代码
git clone <repository-url> /var/www/zentask
cd /var/www/zentask/backend

# 安装依赖
npm ci --only=production

# 配置环境变量
cp .env.example .env
nano .env

# 生成 Prisma 客户端
npx prisma generate

# 运行数据库迁移
npx prisma migrate deploy

# 构建应用
npm run build

# 使用 PM2 启动
pm2 start dist/main.js --name zentask-backend
pm2 save
pm2 startup
```

### 3. 部署前端
```bash
cd /var/www/zentask/frontend

# 安装依赖
npm ci

# 构建生产版本
npm run build

# 复制构建文件到 Nginx 目录
sudo cp -r dist/* /var/www/html/zentask/
```

### 4. 配置 Nginx
```bash
# 创建 Nginx 配置
sudo nano /etc/nginx/sites-available/zentask
```

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/html/zentask;
    index index.html;

    # 前端路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 代理
    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

```bash
# 启用站点
sudo ln -s /etc/nginx/sites-available/zentask /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. SSL 证书 (Let's Encrypt)
```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx -y

# 获取证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 监控与维护

### 1. 日志管理
```bash
# 查看 PM2 日志
pm2 logs zentask-backend

# 查看 Nginx 日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# 查看系统日志
journalctl -u nginx -f
```

### 2. 性能监控
```bash
# PM2 监控
pm2 monit

# 系统资源监控
htop
iostat
```

### 3. 备份策略
```bash
# 数据库备份脚本
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
mysqldump -u root -p zentask > /backup/zentask_$DATE.sql
find /backup -name "zentask_*.sql" -mtime +7 -delete
```

### 4. 更新部署
```bash
# 拉取最新代码
cd /var/www/zentask
git pull origin main

# 更新后端
cd backend
npm ci --only=production
npx prisma migrate deploy
npm run build
pm2 restart zentask-backend

# 更新前端
cd ../frontend
npm ci
npm run build
sudo cp -r dist/* /var/www/html/zentask/
```

## 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查 MySQL 服务状态
   - 验证数据库连接字符串
   - 确认防火墙设置

2. **前端页面空白**
   - 检查构建是否成功
   - 验证 Nginx 配置
   - 查看浏览器控制台错误

3. **API 请求失败**
   - 检查后端服务状态
   - 验证 Nginx 代理配置
   - 查看后端日志

4. **性能问题**
   - 检查服务器资源使用
   - 优化数据库查询
   - 启用缓存和压缩

### 联系支持
如遇到部署问题，请提供以下信息：
- 操作系统版本
- Node.js 版本
- 错误日志
- 配置文件内容
