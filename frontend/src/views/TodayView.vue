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
                  今天
                </h1>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {{ formatDate(new Date()) }} · {{ todayTasks.length }} 个任务
                </p>
              </div>
              
              <BaseButton @click="showCreateTask = true">
                <PlusIcon class="h-4 w-4 mr-2" />
                添加任务
              </BaseButton>
            </div>
          </header>
          
          <!-- 内容区域 -->
          <div class="flex-1 overflow-hidden">
            <div class="h-full p-6">
              <LoadingSpinner v-if="tasksStore.loading" center text="加载今日任务..." />
              
              <div v-else-if="todayTasks.length === 0" class="flex flex-col items-center justify-center h-full text-center">
                <div class="w-24 h-24 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4">
                  <CalendarDaysIcon class="h-12 w-12 text-gray-400" />
                </div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
                  今天没有任务
                </h3>
                <p class="text-gray-600 dark:text-gray-400 mb-6 max-w-sm">
                  看起来您今天没有安排任务。添加一些任务来保持高效！
                </p>
                <BaseButton @click="showCreateTask = true">
                  <PlusIcon class="h-4 w-4 mr-2" />
                  添加今日任务
                </BaseButton>
              </div>
              
              <div v-else class="space-y-4">
                <!-- 任务统计 -->
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                  <BaseCard padding="md">
                    <div class="text-center">
                      <div class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                        {{ todayTasks.length }}
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
                </div>
                
                <!-- 任务列表 -->
                <BaseCard>
                  <template #header>
                    <div class="flex items-center justify-between">
                      <h3 class="text-lg font-semibold">今日任务</h3>
                      <div class="text-sm text-gray-600 dark:text-gray-400">
                        进度: {{ Math.round((completedCount / todayTasks.length) * 100) }}%
                      </div>
                    </div>
                  </template>
                  
                  <div class="space-y-2">
                    <!-- 进度条 -->
                    <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 mb-4">
                      <div 
                        class="bg-green-600 h-2 rounded-full transition-all duration-300"
                        :style="{ width: `${(completedCount / todayTasks.length) * 100}%` }"
                      ></div>
                    </div>
                    
                    <!-- 任务项 -->
                    <div v-if="todayTasks.length === 0" class="text-center py-8">
                      <CalendarDaysIcon class="h-12 w-12 text-gray-400 mx-auto mb-4" />
                      <p class="text-gray-500 dark:text-gray-400">今天没有安排任务</p>
                      <p class="text-sm text-gray-400 dark:text-gray-500 mt-1">
                        点击上方"添加任务"按钮来创建新任务
                      </p>
                    </div>

                    <!-- 按项目分组显示任务 -->
                    <div v-else class="space-y-6">
                      <div v-for="group in taskGroups" :key="group.projectId" class="space-y-2">
                        <div class="flex items-center space-x-2 mb-3">
                          <FolderIcon class="h-4 w-4 text-gray-500" />
                          <h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">
                            {{ group.projectName }}
                          </h4>
                          <span class="text-xs text-gray-500 bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded-full">
                            {{ group.tasks.length }}
                          </span>
                        </div>
                        <div class="space-y-2 ml-6">
                          <div
                            v-for="task in group.tasks"
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
                          <span v-if="task.dueDate" class="text-xs text-gray-500 dark:text-gray-400">
                            📅 {{ new Date(task.dueDate).toLocaleDateString() }}
                          </span>

                          <!-- 优先级标签 -->
                          <PriorityLabel :priority="task.priority" />
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
                      </div>
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
      title="创建今日任务"
      size="lg"
      @close="showCreateTask = false"
    >
      <CreateTaskForm
        @created="handleTaskCreated"
        @cancel="showCreateTask = false"
      />
    </BaseModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { PlusIcon, CalendarDaysIcon, PencilIcon, FolderIcon } from '@heroicons/vue/24/outline'
import { useTasksStore } from '@/stores/tasks'
import { useProjectsStore } from '@/stores/projects'
import { formatDate } from '@/utils/date'
import type { Task } from '@/types'

import AppSidebar from '@/components/layout/AppSidebar.vue'
import BaseButton from '@/components/common/BaseButton.vue'
import BaseCard from '@/components/common/BaseCard.vue'
import BaseModal from '@/components/common/BaseModal.vue'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import CreateTaskForm from '@/components/tasks/CreateTaskForm.vue'
import PriorityLabel from '@/components/common/PriorityLabel.vue'

const tasksStore = useTasksStore()
const projectsStore = useProjectsStore()

// 响应式数据
const showCreateTask = ref(false)

// 计算属性
const todayTasks = computed(() => tasksStore.todayTasks)

const completedCount = computed(() => 
  todayTasks.value.filter(task => task.status === 'completed').length
)

const pendingCount = computed(() =>
  todayTasks.value.filter(task => task.status === 'pending').length
)

// 按项目分组任务
const taskGroups = computed(() => {
  const groups = new Map()

  todayTasks.value.forEach(task => {
    const projectId = task.project?.id || 0
    const projectName = task.project?.name || '未分类'

    if (!groups.has(projectId)) {
      groups.set(projectId, {
        projectId,
        projectName,
        tasks: []
      })
    }

    groups.get(projectId).tasks.push(task)
  })

  return Array.from(groups.values()).sort((a, b) => a.projectName.localeCompare(b.projectName))
})

// 方法
const handleToggleTask = async (task: Task) => {
  try {
    await tasksStore.toggleTaskStatus(task.id)
    // 重新获取今日任务
    await tasksStore.fetchTodayTasks()
  } catch (error) {
    console.error('切换任务状态失败:', error)
  }
}

const handleEditTask = (task: Task) => {
  tasksStore.setCurrentTask(task)
  // TODO: 打开编辑任务模态框
}

const handleTaskCreated = (task: Task) => {
  showCreateTask.value = false
  // 重新获取今日任务
  tasksStore.fetchTodayTasks()
}

// 生命周期
onMounted(async () => {
  try {
    // 确保项目列表已加载
    if (projectsStore.projects.length === 0) {
      await projectsStore.fetchProjects()
    }
    await tasksStore.fetchTodayTasks()
  } catch (error) {
    console.error('加载今日任务失败:', error)
  }
})
</script>
