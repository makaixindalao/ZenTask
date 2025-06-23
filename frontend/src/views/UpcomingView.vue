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
                  最近7天
                </h1>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  即将到期的任务 · {{ upcomingTasks.length }} 个任务
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
              <LoadingSpinner v-if="tasksStore.loading" center text="加载即将到期的任务..." />
              
              <div v-else-if="upcomingTasks.length === 0" class="flex flex-col items-center justify-center h-full text-center">
                <div class="w-24 h-24 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4">
                  <ClockIcon class="h-12 w-12 text-gray-400" />
                </div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
                  没有即将到期的任务
                </h3>
                <p class="text-gray-600 dark:text-gray-400 mb-6 max-w-sm">
                  您在未来7天内没有安排任务。保持这种状态或添加一些新任务！
                </p>
                <BaseButton @click="showCreateTask = true">
                  <PlusIcon class="h-4 w-4 mr-2" />
                  添加任务
                </BaseButton>
              </div>
              
              <div v-else class="space-y-6">
                <!-- 按日期分组的任务 -->
                <div
                  v-for="group in groupedTasks"
                  :key="group.date"
                  class="space-y-3"
                >
                  <BaseCard>
                    <template #header>
                      <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold">
                          {{ group.label }}
                        </h3>
                        <span class="text-sm text-gray-600 dark:text-gray-400">
                          {{ group.tasks.length }} 个任务
                        </span>
                      </div>
                    </template>
                    
                    <div class="space-y-2">
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
                            <span v-if="task.project" class="text-xs text-gray-500 dark:text-gray-400">
                              {{ task.project.name }}
                            </span>
                            
                            <!-- 优先级标签 -->
                            <PriorityLabel :priority="task.priority" />
                            
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
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { PlusIcon, ClockIcon, PencilIcon } from '@heroicons/vue/24/outline'
import { useTasksStore } from '@/stores/tasks'
import { formatDate, formatDueDate, isToday, isOverdue, isTomorrow } from '@/utils/date'
import dayjs from 'dayjs'
import type { Task } from '@/types'

import AppSidebar from '@/components/layout/AppSidebar.vue'
import BaseButton from '@/components/common/BaseButton.vue'
import BaseCard from '@/components/common/BaseCard.vue'
import BaseModal from '@/components/common/BaseModal.vue'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import PriorityLabel from '@/components/common/PriorityLabel.vue'

const tasksStore = useTasksStore()

// 响应式数据
const showCreateTask = ref(false)

// 计算属性
const upcomingTasks = computed(() => tasksStore.upcomingTasks)

const groupedTasks = computed(() => {
  const groups: Array<{ date: string; label: string; tasks: Task[] }> = []
  const tasksByDate = new Map<string, Task[]>()
  
  // 按日期分组
  upcomingTasks.value.forEach(task => {
    if (!task.dueDate) return
    
    const dateKey = dayjs(task.dueDate).format('YYYY-MM-DD')
    if (!tasksByDate.has(dateKey)) {
      tasksByDate.set(dateKey, [])
    }
    tasksByDate.get(dateKey)!.push(task)
  })
  
  // 生成标签并排序
  const sortedDates = Array.from(tasksByDate.keys()).sort()
  
  sortedDates.forEach(dateKey => {
    const date = dayjs(dateKey)
    let label = ''
    
    if (isToday(dateKey)) {
      label = '今天'
    } else if (isTomorrow(dateKey)) {
      label = '明天'
    } else if (isOverdue(dateKey)) {
      label = `逾期 (${date.format('MM-DD')})`
    } else {
      const daysFromNow = date.diff(dayjs(), 'day')
      if (daysFromNow <= 7) {
        label = `${daysFromNow} 天后 (${date.format('MM-DD')})`
      } else {
        label = date.format('MM-DD')
      }
    }
    
    groups.push({
      date: dateKey,
      label,
      tasks: tasksByDate.get(dateKey)!
    })
  })
  
  return groups
})

// 方法
const handleToggleTask = async (task: Task) => {
  try {
    await tasksStore.toggleTaskStatus(task.id)
    // 重新获取即将到期的任务
    await tasksStore.fetchUpcomingTasks()
  } catch (error) {
    console.error('切换任务状态失败:', error)
  }
}

const handleEditTask = (task: Task) => {
  tasksStore.setCurrentTask(task)
  // TODO: 打开编辑任务模态框
}

// 生命周期
onMounted(async () => {
  try {
    await tasksStore.fetchUpcomingTasks()
  } catch (error) {
    console.error('加载即将到期的任务失败:', error)
  }
})
</script>
