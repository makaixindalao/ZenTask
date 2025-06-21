<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
    <div class="flex h-screen">
      <AppSidebar />
      
      <main class="flex-1 overflow-hidden">
        <div class="h-full flex flex-col">
          <!-- 头部 -->
          <header class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-6 py-4">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                  {{ currentProject?.name || '项目' }}
                </h1>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {{ projectTasks.length }} 个任务
                </p>
              </div>
              
              <div class="flex items-center space-x-3">
                <!-- 项目操作 -->
                <button
                  v-if="currentProject && !currentProject.isInbox"
                  @click="showEditProject = true"
                  class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                  title="编辑项目"
                >
                  <PencilIcon class="h-5 w-5" />
                </button>
                
                <BaseButton @click="showCreateTask = true">
                  <PlusIcon class="h-4 w-4 mr-2" />
                  添加任务
                </BaseButton>
              </div>
            </div>
          </header>
          
          <!-- 内容区域 -->
          <div class="flex-1 overflow-hidden">
            <div class="h-full p-6">
              <LoadingSpinner v-if="projectsStore.loading || tasksStore.loading" center text="加载项目..." />
              
              <div v-else-if="!currentProject" class="flex flex-col items-center justify-center h-full text-center">
                <div class="w-24 h-24 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4">
                  <FolderIcon class="h-12 w-12 text-gray-400" />
                </div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
                  项目不存在
                </h3>
                <p class="text-gray-600 dark:text-gray-400 mb-6">
                  您访问的项目不存在或已被删除。
                </p>
                <BaseButton @click="$router.push('/dashboard')">
                  返回收件箱
                </BaseButton>
              </div>
              
              <div v-else-if="projectTasks.length === 0" class="flex flex-col items-center justify-center h-full text-center">
                <div class="w-24 h-24 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4">
                  <FolderIcon class="h-12 w-12 text-gray-400" />
                </div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
                  项目为空
                </h3>
                <p class="text-gray-600 dark:text-gray-400 mb-6 max-w-sm">
                  这个项目还没有任务。开始添加任务来组织您的工作。
                </p>
                <BaseButton @click="showCreateTask = true">
                  <PlusIcon class="h-4 w-4 mr-2" />
                  添加第一个任务
                </BaseButton>
              </div>
              
              <div v-else class="space-y-4">
                <!-- 项目统计 -->
                <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                  <BaseCard padding="md">
                    <div class="text-center">
                      <div class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                        {{ projectTasks.length }}
                      </div>
                      <div class="text-sm text-gray-600 dark:text-gray-400">
                        总任务
                      </div>
                    </div>
                  </BaseCard>
                  
                  <BaseCard padding="md">
                    <div class="text-center">
                      <div class="text-2xl font-bold text-green-600">
                        {{ completedCount }}
                      </div>
                      <div class="text-sm text-gray-600 dark:text-gray-400">
                        已完成
                      </div>
                    </div>
                  </BaseCard>
                  
                  <BaseCard padding="md">
                    <div class="text-center">
                      <div class="text-2xl font-bold text-orange-600">
                        {{ pendingCount }}
                      </div>
                      <div class="text-sm text-gray-600 dark:text-gray-400">
                        待完成
                      </div>
                    </div>
                  </BaseCard>
                  
                  <BaseCard padding="md">
                    <div class="text-center">
                      <div class="text-2xl font-bold text-blue-600">
                        {{ Math.round((completedCount / projectTasks.length) * 100) }}%
                      </div>
                      <div class="text-sm text-gray-600 dark:text-gray-400">
                        完成率
                      </div>
                    </div>
                  </BaseCard>
                </div>
                
                <!-- 任务筛选和排序 -->
                <div class="flex items-center justify-between mb-4">
                  <div class="flex items-center space-x-4">
                    <select
                      v-model="filterStatus"
                      class="text-sm border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
                    >
                      <option value="all">全部任务</option>
                      <option value="pending">未完成</option>
                      <option value="completed">已完成</option>
                    </select>
                    
                    <select
                      v-model="sortBy"
                      class="text-sm border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
                    >
                      <option value="sortOrder">自定义排序</option>
                      <option value="createdAt">创建时间</option>
                      <option value="dueDate">截止日期</option>
                      <option value="priority">优先级</option>
                    </select>
                  </div>
                  
                  <div class="text-sm text-gray-600 dark:text-gray-400">
                    共 {{ filteredTasks.length }} 个任务
                  </div>
                </div>
                
                <!-- 任务列表 -->
                <BaseCard>
                  <div class="space-y-2">
                    <!-- 进度条 -->
                    <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 mb-4">
                      <div 
                        class="bg-green-600 h-2 rounded-full transition-all duration-300"
                        :style="{ width: `${(completedCount / projectTasks.length) * 100}%` }"
                      ></div>
                    </div>
                    
                    <!-- 任务项 -->
                    <div
                      v-for="task in filteredTasks"
                      :key="task.id"
                      class="flex items-center space-x-3 p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                    >
                      <input
                        type="checkbox"
                        :checked="task.status === 'completed'"
                        @change="handleToggleTask(task)"
                        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
                      />
                      
                      <div class="flex-1 min-w-0">
                        <div :class="[
                          'text-sm font-medium',
                          task.status === 'completed' 
                            ? 'line-through text-gray-500 dark:text-gray-400' 
                            : 'text-gray-900 dark:text-gray-100'
                        ]">
                          {{ task.title }}
                        </div>
                        
                        <div v-if="task.description" class="text-xs text-gray-600 dark:text-gray-400 mt-1 truncate">
                          {{ task.description }}
                        </div>
                        
                        <div class="flex items-center space-x-2 mt-1">
                          <span
                            v-if="task.priority !== 'medium'"
                            :class="[
                              'text-xs px-2 py-0.5 rounded-full',
                              task.priority === 'high' 
                                ? 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'
                                : 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
                            ]"
                          >
                            {{ task.priority === 'high' ? '高' : '低' }}优先级
                          </span>
                          
                          <span
                            v-if="task.dueDate"
                            :class="[
                              'text-xs px-2 py-0.5 rounded-full',
                              isOverdue(task.dueDate)
                                ? 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'
                                : isToday(task.dueDate)
                                ? 'bg-orange-100 text-orange-700 dark:bg-orange-900 dark:text-orange-300'
                                : 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300'
                            ]"
                          >
                            {{ formatDueDate(task.dueDate) }}
                          </span>
                        </div>
                      </div>
                      
                      <button
                        @click="handleEditTask(task)"
                        class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                      >
                        <PencilIcon class="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </BaseCard>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    
    <!-- 创建任务模态框 -->
    <BaseModal
      :show="showCreateTask"
      title="创建任务"
      size="lg"
      @close="showCreateTask = false"
    >
      <!-- CreateTaskForm 组件将在后续任务中实现 -->
      <div class="text-center py-8 text-gray-500">
        创建任务表单组件待实现
      </div>
    </BaseModal>
    
    <!-- 编辑项目模态框 -->
    <BaseModal
      :show="showEditProject"
      title="编辑项目"
      @close="showEditProject = false"
    >
      <!-- EditProjectForm 组件将在后续任务中实现 -->
      <div class="text-center py-8 text-gray-500">
        编辑项目表单组件待实现
      </div>
    </BaseModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { PlusIcon, FolderIcon, PencilIcon } from '@heroicons/vue/24/outline'
import { useProjectsStore } from '@/stores/projects'
import { useTasksStore } from '@/stores/tasks'
import { formatDueDate, isToday, isOverdue } from '@/utils/date'
import type { Task } from '@/types'

import AppSidebar from '@/components/layout/AppSidebar.vue'
import BaseButton from '@/components/common/BaseButton.vue'
import BaseCard from '@/components/common/BaseCard.vue'
import BaseModal from '@/components/common/BaseModal.vue'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'

const route = useRoute()
const projectsStore = useProjectsStore()
const tasksStore = useTasksStore()

// 响应式数据
const showCreateTask = ref(false)
const showEditProject = ref(false)
const filterStatus = ref<'all' | 'pending' | 'completed'>('all')
const sortBy = ref<'sortOrder' | 'createdAt' | 'dueDate' | 'priority'>('sortOrder')

// 计算属性
const projectId = computed(() => Number(route.params.id))
const currentProject = computed(() => projectsStore.currentProject)
const projectTasks = computed(() => tasksStore.tasks)

const completedCount = computed(() => 
  projectTasks.value.filter(task => task.status === 'completed').length
)

const pendingCount = computed(() => 
  projectTasks.value.filter(task => task.status === 'pending').length
)

const filteredTasks = computed(() => {
  let filtered = projectTasks.value

  // 状态筛选
  if (filterStatus.value !== 'all') {
    filtered = filtered.filter(task => task.status === filterStatus.value)
  }

  // 排序
  filtered = [...filtered].sort((a, b) => {
    switch (sortBy.value) {
      case 'createdAt':
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      case 'dueDate':
        if (!a.dueDate && !b.dueDate) return 0
        if (!a.dueDate) return 1
        if (!b.dueDate) return -1
        return new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime()
      case 'priority':
        const priorityOrder = { high: 3, medium: 2, low: 1 }
        return priorityOrder[b.priority] - priorityOrder[a.priority]
      case 'sortOrder':
      default:
        return a.sortOrder - b.sortOrder
    }
  })

  return filtered
})

// 方法
const handleToggleTask = async (task: Task) => {
  try {
    await tasksStore.toggleTaskStatus(task.id)
  } catch (error) {
    console.error('切换任务状态失败:', error)
  }
}

const handleEditTask = (task: Task) => {
  tasksStore.setCurrentTask(task)
  // TODO: 打开编辑任务模态框
}

const loadProjectData = async () => {
  try {
    await Promise.all([
      projectsStore.fetchProject(projectId.value),
      tasksStore.fetchTasks({ projectId: projectId.value })
    ])
  } catch (error) {
    console.error('加载项目数据失败:', error)
  }
}

// 监听路由变化
watch(() => route.params.id, () => {
  if (route.params.id) {
    loadProjectData()
  }
}, { immediate: true })

// 生命周期
onMounted(() => {
  if (projectId.value) {
    loadProjectData()
  }
})
</script>
