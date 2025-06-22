import api from './index'
import type { Project, CreateProjectRequest, UpdateProjectRequest } from '@/types'

export const projectsApi = {
  // 获取所有项目
  getAll: async (): Promise<Project[]> => {
    return await api.get('/projects')
  },

  // 获取单个项目
  getById: async (id: number): Promise<Project> => {
    return await api.get(`/projects/${id}`)
  },

  // 创建项目
  create: async (data: CreateProjectRequest): Promise<Project> => {
    return await api.post('/projects', data)
  },

  // 更新项目
  update: async (id: number, data: UpdateProjectRequest): Promise<Project> => {
    return await api.patch(`/projects/${id}`, data)
  },

  // 删除项目
  delete: async (id: number): Promise<void> => {
    return await api.delete(`/projects/${id}`)
  },
}
