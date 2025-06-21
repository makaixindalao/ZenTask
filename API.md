# ZenTask API 文档

## 基础信息

- **Base URL**: `http://localhost:3000/api`
- **认证方式**: Bearer Token (JWT)
- **Content-Type**: `application/json`

## 认证接口

### 用户注册
```http
POST /auth/register
```

**请求体**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "email": "user@example.com",
      "createdAt": "2025-06-21T10:00:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 用户登录
```http
POST /auth/login
```

**请求体**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "rememberMe": false
}
```

**响应**: 同注册接口

### 验证Token
```http
GET /auth/verify
Authorization: Bearer <token>
```

**响应**:
```json
{
  "success": true,
  "data": {
    "valid": true,
    "user": {
      "id": 1,
      "email": "user@example.com"
    }
  }
}
```

## 项目管理接口

### 获取项目列表
```http
GET /projects
Authorization: Bearer <token>
```

**响应**:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "userId": 1,
      "name": "收件箱",
      "isInbox": true,
      "createdAt": "2025-06-21T10:00:00.000Z",
      "taskCount": 5,
      "uncompletedTaskCount": 3
    }
  ]
}
```

### 创建项目
```http
POST /projects
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "name": "工作项目"
}
```

### 更新项目
```http
PATCH /projects/:id
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "name": "新项目名称"
}
```

### 删除项目
```http
DELETE /projects/:id
Authorization: Bearer <token>
```

## 任务管理接口

### 获取任务列表
```http
GET /tasks?projectId=1&status=pending&page=1&limit=20
Authorization: Bearer <token>
```

**查询参数**:
- `projectId`: 项目ID
- `status`: 任务状态 (`pending`, `completed`)
- `priority`: 优先级 (`low`, `medium`, `high`)
- `dueDate`: 截止日期 (YYYY-MM-DD)
- `page`: 页码
- `limit`: 每页数量
- `sortBy`: 排序字段 (`createdAt`, `dueDate`, `priority`, `sortOrder`)
- `sortOrder`: 排序方向 (`asc`, `desc`)

**响应**:
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "userId": 1,
        "projectId": 1,
        "title": "完成项目文档",
        "description": "编写API文档和部署指南",
        "status": "pending",
        "priority": "high",
        "dueDate": "2025-06-25",
        "sortOrder": 1,
        "createdAt": "2025-06-21T10:00:00.000Z",
        "updatedAt": "2025-06-21T10:00:00.000Z",
        "project": {
          "id": 1,
          "name": "收件箱",
          "isInbox": true
        }
      }
    ],
    "total": 10,
    "page": 1,
    "limit": 20,
    "totalPages": 1
  }
}
```

### 创建任务
```http
POST /tasks
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "projectId": 1,
  "title": "新任务",
  "description": "任务描述",
  "priority": "medium",
  "dueDate": "2025-06-25"
}
```

### 更新任务
```http
PATCH /tasks/:id
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "title": "更新的任务标题",
  "status": "completed",
  "priority": "high",
  "dueDate": "2025-06-26"
}
```

### 删除任务
```http
DELETE /tasks/:id
Authorization: Bearer <token>
```

### 获取今日任务
```http
GET /tasks/today
Authorization: Bearer <token>
```

### 获取即将到期任务
```http
GET /tasks/upcoming
Authorization: Bearer <token>
```

### 任务重新排序
```http
POST /tasks/reorder
Authorization: Bearer <token>
```

**请求体**:
```json
{
  "tasks": [
    {
      "id": 1,
      "sortOrder": 1
    },
    {
      "id": 2,
      "sortOrder": 2
    }
  ]
}
```

## 错误响应

所有错误响应都遵循以下格式:

```json
{
  "success": false,
  "statusCode": 400,
  "timestamp": "2025-06-21T10:00:00.000Z",
  "path": "/api/tasks",
  "method": "POST",
  "message": "任务标题不能为空"
}
```

### 常见错误码

- `400 Bad Request`: 请求参数错误
- `401 Unauthorized`: 未认证或token无效
- `403 Forbidden`: 权限不足
- `404 Not Found`: 资源不存在
- `409 Conflict`: 资源冲突（如邮箱已存在）
- `422 Unprocessable Entity`: 数据验证失败
- `500 Internal Server Error`: 服务器内部错误

## 数据模型

### User
```typescript
interface User {
  id: number
  email: string
  createdAt: string
}
```

### Project
```typescript
interface Project {
  id: number
  userId: number
  name: string
  isInbox: boolean
  createdAt: string
  taskCount?: number
  uncompletedTaskCount?: number
}
```

### Task
```typescript
interface Task {
  id: number
  userId: number
  projectId: number
  title: string
  description?: string
  status: 'pending' | 'completed'
  priority: 'low' | 'medium' | 'high'
  dueDate?: string
  sortOrder: number
  createdAt: string
  updatedAt: string
  project?: Project
}
```

## 限制说明

- 任务标题最大长度: 255字符
- 任务描述最大长度: 2000字符
- 项目名称最大长度: 100字符
- 每分钟API请求限制: 100次
- 分页最大限制: 100条/页

## 示例代码

### JavaScript/TypeScript
```typescript
// 登录
const response = await fetch('/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'password123'
  })
})

const { data } = await response.json()
const token = data.token

// 获取任务列表
const tasksResponse = await fetch('/api/tasks?projectId=1', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
})

const tasks = await tasksResponse.json()
```

### cURL
```bash
# 登录
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# 获取任务列表
curl -X GET http://localhost:3000/api/tasks \
  -H "Authorization: Bearer <token>"

# 创建任务
curl -X POST http://localhost:3000/api/tasks \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"projectId":1,"title":"新任务","priority":"medium"}'
```
