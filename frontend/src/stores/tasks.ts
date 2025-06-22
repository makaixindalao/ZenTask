import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type {
  Task,
  CreateTaskRequest,
  UpdateTaskRequest,
  TaskQueryParams,
  ReorderTasksRequest,
  PaginatedResponse,
  TaskStatus
} from '@/types'
import { tasksApi } from '@/api/tasks'

export const useTasksStore = defineStore('tasks', () => {
  // 状态
  const tasks = ref<Task[]>([])
  const todayTasks = ref<Task[]>([])
  const upcomingTasks = ref<Task[]>([])
  const currentTask = ref<Task | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const pagination = ref({
    total: 0,
    page: 1,
    limit: 20,
    totalPages: 0
  })

  // 计算属性
  const pendingTasks = computed(() =>
    tasks.value.filter(task => task.status === 'pending')
  )

  const completedTasks = computed(() =>
    tasks.value.filter(task => task.status === 'completed')
  )

  // 动作
  const fetchTasks = async (params?: TaskQueryParams): Promise<void> => {
    try {
      loading.value = true
      error.value = null

      const response: PaginatedResponse<Task> = await tasksApi.getAll(params)

      tasks.value = response.data
      pagination.value = {
        total: response.total,
        page: response.page,
        limit: response.limit,
        totalPages: response.totalPages || Math.ceil(response.total / response.limit)
      }
    } catch (err: any) {
      error.value = err.response?.data?.message || '获取任务列表失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const fetchTodayTasks = async (): Promise<void> => {
    try {
      loading.value = true
      error.value = null
      todayTasks.value = await tasksApi.getToday()
    } catch (err: any) {
      error.value = err.response?.data?.message || '获取今日任务失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const fetchUpcomingTasks = async (): Promise<void> => {
    try {
      loading.value = true
      error.value = null
      upcomingTasks.value = await tasksApi.getUpcoming()
    } catch (err: any) {
      error.value = err.response?.data?.message || '获取即将到期任务失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const fetchTask = async (id: number): Promise<void> => {
    try {
      loading.value = true
      error.value = null
      currentTask.value = await tasksApi.getById(id)
    } catch (err: any) {
      error.value = err.response?.data?.message || '获取任务详情失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const createTask = async (data: CreateTaskRequest): Promise<Task> => {
    try {
      loading.value = true
      error.value = null

      const newTask = await tasksApi.create(data)
      tasks.value.unshift(newTask)

      // 触发项目数据刷新以更新任务数量统计
      const { useProjectsStore } = await import('./projects')
      const projectsStore = useProjectsStore()
      await projectsStore.fetchProjects()

      return newTask
    } catch (err: any) {
      error.value = err.response?.data?.message || '创建任务失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const updateTask = async (id: number, data: UpdateTaskRequest): Promise<Task> => {
    try {
      loading.value = true
      error.value = null

      const updatedTask = await tasksApi.update(id, data)

      const index = tasks.value.findIndex(t => t.id === id)
      if (index !== -1) {
        tasks.value[index] = updatedTask
      }

      if (currentTask.value?.id === id) {
        currentTask.value = updatedTask
      }

      // 如果更新了任务状态，需要刷新项目数据以更新任务数量统计
      if (data.status) {
        const { useProjectsStore } = await import('./projects')
        const projectsStore = useProjectsStore()
        await projectsStore.fetchProjects()
      }

      return updatedTask
    } catch (err: any) {
      error.value = err.response?.data?.message || '更新任务失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const deleteTask = async (id: number): Promise<void> => {
    try {
      loading.value = true
      error.value = null

      await tasksApi.delete(id)

      tasks.value = tasks.value.filter(t => t.id !== id)
      todayTasks.value = todayTasks.value.filter(t => t.id !== id)
      upcomingTasks.value = upcomingTasks.value.filter(t => t.id !== id)

      if (currentTask.value?.id === id) {
        currentTask.value = null
      }

      // 触发项目数据刷新以更新任务数量统计
      const { useProjectsStore } = await import('./projects')
      const projectsStore = useProjectsStore()
      await projectsStore.fetchProjects()
    } catch (err: any) {
      error.value = err.response?.data?.message || '删除任务失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const toggleTaskStatus = async (id: number): Promise<void> => {
    const task = tasks.value.find(t => t.id === id)
    if (!task) return

    const newStatus: TaskStatus = task.status === 'pending' ? 'completed' : 'pending'
    await updateTask(id, { status: newStatus })
  }

  const reorderTasks = async (data: ReorderTasksRequest): Promise<void> => {
    try {
      loading.value = true
      error.value = null

      await tasksApi.reorder(data)

      // 更新本地任务排序
      data.tasks.forEach(({ id, sortOrder }) => {
        const task = tasks.value.find(t => t.id === id)
        if (task) {
          task.sortOrder = sortOrder
        }
      })

      // 重新排序任务列表
      tasks.value.sort((a, b) => a.sortOrder - b.sortOrder)
    } catch (err: any) {
      error.value = err.response?.data?.message || '任务排序失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const setCurrentTask = (task: Task | null): void => {
    currentTask.value = task
  }

  const clearError = (): void => {
    error.value = null
  }

  return {
    // 状态
    tasks,
    todayTasks,
    upcomingTasks,
    currentTask,
    loading,
    error,
    pagination,
    // 计算属性
    pendingTasks,
    completedTasks,
    // 动作
    fetchTasks,
    fetchTodayTasks,
    fetchUpcomingTasks,
    fetchTask,
    createTask,
    updateTask,
    deleteTask,
    toggleTaskStatus,
    reorderTasks,
    setCurrentTask,
    clearError
  }
})
