// 用户相关类型
export interface User {
  id: number
  email: string
  createdAt: string
}

export interface LoginRequest {
  email: string
  password: string
  rememberMe?: boolean
}

export interface RegisterRequest {
  email: string
  password: string
}

export interface AuthResponse {
  user: User
  token: string
}

// 项目相关类型
export interface Project {
  id: number
  userId: number
  name: string
  showInToday: boolean
  createdAt: string
  taskCount?: number
  uncompletedTaskCount?: number
}

export interface CreateProjectRequest {
  name: string
}

export interface UpdateProjectRequest {
  name?: string
  showInToday?: boolean
}

// 任务相关类型
export type TaskStatus = 'pending' | 'completed'
export type TaskPriority = 'low' | 'medium' | 'high'

export interface Task {
  id: number
  userId: number
  projectId: number
  title: string
  description?: string
  status: TaskStatus
  priority: TaskPriority
  dueDate?: string
  sortOrder: number
  createdAt: string
  updatedAt: string
  project?: Project
}

export interface CreateTaskRequest {
  projectId: number
  title: string
  description?: string
  priority?: TaskPriority
  dueDate?: string
}

export interface UpdateTaskRequest {
  title?: string
  description?: string
  status?: TaskStatus
  priority?: TaskPriority
  dueDate?: string
}

export interface ReorderTasksRequest {
  tasks: Array<{
    id: number
    sortOrder: number
  }>
}

// API 响应类型
export interface ApiResponse<T = any> {
  success: boolean
  data: T
  message?: string
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
}

// 查询参数类型
export interface TaskQueryParams {
  projectId?: number
  status?: TaskStatus
  priority?: TaskPriority
  dueDate?: string
  page?: number
  limit?: number
  sortBy?: 'createdAt' | 'dueDate' | 'priority' | 'sortOrder'
  sortOrder?: 'asc' | 'desc'
}

// 视图类型
export type ViewType = 'inbox' | 'today' | 'upcoming' | 'project'

// 主题类型
export type ThemeMode = 'light' | 'dark' | 'system'
