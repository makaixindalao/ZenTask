import api from './index'
import type { 
  Task, 
  CreateTaskRequest, 
  UpdateTaskRequest, 
  TaskQueryParams, 
  ReorderTasksRequest,
  PaginatedResponse 
} from '@/types'

export const tasksApi = {
  // 获取任务列表
  getAll: async (params?: TaskQueryParams): Promise<PaginatedResponse<Task>> => {
    return await api.get('/tasks', { params })
  },

  // 获取今天的任务
  getToday: async (): Promise<Task[]> => {
    return await api.get('/tasks/today')
  },

  // 获取即将到期的任务
  getUpcoming: async (): Promise<Task[]> => {
    return await api.get('/tasks/upcoming')
  },

  // 获取单个任务
  getById: async (id: number): Promise<Task> => {
    return await api.get(`/tasks/${id}`)
  },

  // 创建任务
  create: async (data: CreateTaskRequest): Promise<Task> => {
    return await api.post('/tasks', data)
  },

  // 更新任务
  update: async (id: number, data: UpdateTaskRequest): Promise<Task> => {
    return await api.patch(`/tasks/${id}`, data)
  },

  // 删除任务
  delete: async (id: number): Promise<void> => {
    return await api.delete(`/tasks/${id}`)
  },

  // 重新排序任务
  reorder: async (data: ReorderTasksRequest): Promise<void> => {
    return await api.post('/tasks/reorder', data)
  },
}
