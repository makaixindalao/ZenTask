import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { Project, CreateProjectRequest, UpdateProjectRequest } from '@/types'
import { projectsApi } from '@/api/projects'

export const useProjectsStore = defineStore('projects', () => {
  // 状态
  const projects = ref<Project[]>([])
  const currentProject = ref<Project | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 计算属性
  const customProjects = computed(() => projects.value)

  // 动作
  const fetchProjects = async (): Promise<void> => {
    try {
      loading.value = true
      error.value = null
      projects.value = await projectsApi.getAll()
    } catch (err: any) {
      error.value = err.response?.data?.message || '获取项目列表失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const fetchProject = async (id: number): Promise<void> => {
    try {
      loading.value = true
      error.value = null
      currentProject.value = await projectsApi.getById(id)
    } catch (err: any) {
      error.value = err.response?.data?.message || '获取项目详情失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const createProject = async (data: CreateProjectRequest): Promise<Project> => {
    try {
      loading.value = true
      error.value = null

      const newProject = await projectsApi.create(data)
      projects.value.push(newProject)

      return newProject
    } catch (err: any) {
      error.value = err.response?.data?.message || '创建项目失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const updateProject = async (id: number, data: UpdateProjectRequest): Promise<Project> => {
    try {
      loading.value = true
      error.value = null

      const updatedProject = await projectsApi.update(id, data)

      const index = projects.value.findIndex(p => p.id === id)
      if (index !== -1) {
        projects.value[index] = updatedProject
      }

      if (currentProject.value?.id === id) {
        currentProject.value = updatedProject
      }

      return updatedProject
    } catch (err: any) {
      error.value = err.response?.data?.message || '更新项目失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const deleteProject = async (id: number): Promise<void> => {
    try {
      loading.value = true
      error.value = null

      await projectsApi.delete(id)

      projects.value = projects.value.filter(p => p.id !== id)

      if (currentProject.value?.id === id) {
        currentProject.value = null
      }
    } catch (err: any) {
      error.value = err.response?.data?.message || '删除项目失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const setCurrentProject = (project: Project | null): void => {
    currentProject.value = project
  }

  const clearError = (): void => {
    error.value = null
  }

  return {
    // 状态
    projects,
    currentProject,
    loading,
    error,
    // 计算属性
    customProjects,
    // 动作
    fetchProjects,
    fetchProject,
    createProject,
    updateProject,
    deleteProject,
    setCurrentProject,
    clearError
  }
})
