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
                  日历视图
                </h1>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {{ currentMonthYear }} · 查看和管理您的任务
                </p>
              </div>
              
              <div class="flex items-center space-x-4">
                <div class="flex items-center space-x-2">
                  <button
                    @click="previousMonth"
                    class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                  >
                    <ChevronLeftIcon class="h-5 w-5" />
                  </button>
                  <button
                    @click="goToToday"
                    class="px-3 py-1 text-sm font-medium text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-md transition-colors"
                  >
                    今天
                  </button>
                  <button
                    @click="nextMonth"
                    class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                  >
                    <ChevronRightIcon class="h-5 w-5" />
                  </button>
                </div>
                
                <BaseButton @click="showCreateTask = true">
                  <PlusIcon class="h-4 w-4 mr-2" />
                  添加任务
                </BaseButton>
              </div>
            </div>
          </header>

          <!-- 日历主体 -->
          <div class="flex-1 p-6 overflow-auto">
            <div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
              <!-- 星期标题 -->
              <div class="grid grid-cols-7 border-b border-gray-200 dark:border-gray-700">
                <div
                  v-for="day in weekDays"
                  :key="day"
                  class="p-4 text-center text-sm font-medium text-gray-500 dark:text-gray-400"
                >
                  {{ day }}
                </div>
              </div>

              <!-- 日历网格 -->
              <div class="grid grid-cols-7">
                <div
                  v-for="date in calendarDates"
                  :key="date.dateString"
                  :class="[
                    'min-h-[120px] border-r border-b border-gray-200 dark:border-gray-700 p-2 cursor-pointer transition-colors',
                    date.isCurrentMonth 
                      ? 'bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700' 
                      : 'bg-gray-50 dark:bg-gray-900 text-gray-400',
                    date.isToday ? 'bg-blue-50 dark:bg-blue-900/20' : '',
                    selectedDate === date.dateString ? 'ring-2 ring-blue-500' : ''
                  ]"
                  @click="selectDate(date)"
                >
                  <!-- 日期数字 -->
                  <div class="flex items-center justify-between mb-1">
                    <span
                      :class="[
                        'text-sm font-medium',
                        date.isToday 
                          ? 'bg-blue-600 text-white rounded-full w-6 h-6 flex items-center justify-center' 
                          : date.isCurrentMonth 
                          ? 'text-gray-900 dark:text-gray-100' 
                          : 'text-gray-400'
                      ]"
                    >
                      {{ date.day }}
                    </span>
                    
                    <!-- 任务数量指示器 -->
                    <span
                      v-if="getTasksForDate(date.dateString).length > 0"
                      class="text-xs bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center"
                    >
                      {{ getTasksForDate(date.dateString).length }}
                    </span>
                  </div>

                  <!-- 任务预览 -->
                  <div class="space-y-1">
                    <div
                      v-for="task in getTasksForDate(date.dateString).slice(0, 3)"
                      :key="task.id"
                      :class="[
                        'text-xs p-1 rounded truncate',
                        task.status === 'completed' 
                          ? 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300 line-through' 
                          : task.priority === 'high'
                          ? 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'
                          : task.priority === 'medium'
                          ? 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300'
                          : 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300'
                      ]"
                    >
                      {{ task.title }}
                    </div>
                    
                    <!-- 更多任务指示器 -->
                    <div
                      v-if="getTasksForDate(date.dateString).length > 3"
                      class="text-xs text-gray-500 dark:text-gray-400"
                    >
                      +{{ getTasksForDate(date.dateString).length - 3 }} 更多
                    </div>
                  </div>
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
      <CreateTaskForm
        :due-date="selectedDateForTask"
        @created="handleTaskCreated"
        @cancel="showCreateTask = false"
      />
    </BaseModal>

    <!-- 日期任务详情模态框 -->
    <BaseModal
      :show="showDateTasks"
      :title="`${selectedDateDisplay} 的任务`"
      size="lg"
      @close="showDateTasks = false"
    >
      <div v-if="selectedDateTasks.length === 0" class="text-center py-8">
        <CalendarDaysIcon class="h-12 w-12 text-gray-400 mx-auto mb-4" />
        <p class="text-gray-500 dark:text-gray-400">这一天没有任务</p>
        <BaseButton @click="createTaskForSelectedDate" class="mt-4">
          <PlusIcon class="h-4 w-4 mr-2" />
          为这一天创建任务
        </BaseButton>
      </div>
      
      <div v-else class="space-y-3">
        <div
          v-for="task in selectedDateTasks"
          :key="task.id"
          class="flex items-center space-x-3 p-3 rounded-lg border border-gray-200 dark:border-gray-700"
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
            
            <div v-if="task.description" class="text-xs text-gray-600 dark:text-gray-400 mt-1">
              {{ task.description }}
            </div>
            
            <div class="flex items-center space-x-2 mt-1">
              <!-- 项目标签 -->
              <span
                v-if="task.project"
                class="text-xs px-2 py-0.5 rounded-full bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300"
              >
                {{ task.project.name }}
              </span>

              <!-- 优先级标签 -->
              <PriorityLabel
                :priority="task.priority"
                variant="compact"
                size="xs"
              />
            </div>
          </div>
        </div>
        
        <div class="pt-4 border-t border-gray-200 dark:border-gray-700">
          <BaseButton @click="createTaskForSelectedDate" variant="secondary" class="w-full">
            <PlusIcon class="h-4 w-4 mr-2" />
            为这一天添加更多任务
          </BaseButton>
        </div>
      </div>
    </BaseModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { 
  PlusIcon, 
  CalendarDaysIcon, 
  ChevronLeftIcon, 
  ChevronRightIcon 
} from '@heroicons/vue/24/outline'
import { useTasksStore } from '@/stores/tasks'
import { useProjectsStore } from '@/stores/projects'
import { formatLocalDate, getTodayString } from '@/utils/date'
import type { Task } from '@/types'

import AppSidebar from '@/components/layout/AppSidebar.vue'
import BaseButton from '@/components/common/BaseButton.vue'
import BaseModal from '@/components/common/BaseModal.vue'
import CreateTaskForm from '@/components/tasks/CreateTaskForm.vue'
import PriorityLabel from '@/components/common/PriorityLabel.vue'

const tasksStore = useTasksStore()
const projectsStore = useProjectsStore()

// 响应式数据
const currentDate = ref(new Date())
const selectedDate = ref('')
const showCreateTask = ref(false)
const showDateTasks = ref(false)

// 星期标题
const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']

// 计算属性
const currentMonthYear = computed(() => {
  return currentDate.value.toLocaleDateString('zh-CN', { 
    year: 'numeric', 
    month: 'long' 
  })
})

const selectedDateForTask = computed(() => {
  return selectedDate.value || getTodayString()
})

const selectedDateDisplay = computed(() => {
  if (!selectedDate.value) return ''
  return new Date(selectedDate.value).toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
})

const selectedDateTasks = computed(() => {
  return getTasksForDate(selectedDate.value)
})

// 生成日历日期
const calendarDates = computed(() => {
  const year = currentDate.value.getFullYear()
  const month = currentDate.value.getMonth()

  // 获取当月第一天和最后一天
  const firstDay = new Date(year, month, 1)
  const lastDay = new Date(year, month + 1, 0)

  // 获取第一周的开始日期（可能是上个月的日期）
  const startDate = new Date(firstDay)
  startDate.setDate(startDate.getDate() - firstDay.getDay())

  // 获取最后一周的结束日期（可能是下个月的日期）
  const endDate = new Date(lastDay)
  endDate.setDate(endDate.getDate() + (6 - lastDay.getDay()))

  const dates = []
  const current = new Date(startDate)

  while (current <= endDate) {
    // 使用本地日期格式，避免时区偏移问题
    const dateString = formatLocalDate(current)
    const todayString = getTodayString()

    dates.push({
      date: new Date(current),
      dateString,
      day: current.getDate(),
      isCurrentMonth: current.getMonth() === month,
      isToday: dateString === todayString
    })

    current.setDate(current.getDate() + 1)
  }

  return dates
})

// 方法
const getTasksForDate = (dateString: string): Task[] => {
  if (!dateString) return []

  return tasksStore.tasks.filter(task => {
    // 检查任务的截止日期
    if (task.dueDate) {
      const taskDate = formatLocalDate(new Date(task.dueDate))
      return taskDate === dateString
    }

    // 检查任务的创建日期（对于没有截止日期的任务）
    const createdDate = formatLocalDate(new Date(task.createdAt))
    return createdDate === dateString
  })
}

const selectDate = (date: any) => {
  selectedDate.value = date.dateString
  showDateTasks.value = true
}

const previousMonth = () => {
  const newDate = new Date(currentDate.value)
  newDate.setMonth(newDate.getMonth() - 1)
  currentDate.value = newDate
}

const nextMonth = () => {
  const newDate = new Date(currentDate.value)
  newDate.setMonth(newDate.getMonth() + 1)
  currentDate.value = newDate
}

const goToToday = () => {
  currentDate.value = new Date()
}

const createTaskForSelectedDate = () => {
  showDateTasks.value = false
  showCreateTask.value = true
}

const handleTaskCreated = (task: Task) => {
  showCreateTask.value = false
  // 重新获取任务数据
  tasksStore.fetchTasks()
}

const handleToggleTask = async (task: Task) => {
  try {
    await tasksStore.toggleTaskStatus(task.id)
    // 重新获取任务数据
    await tasksStore.fetchTasks()
  } catch (error) {
    console.error('切换任务状态失败:', error)
  }
}

// 生命周期
onMounted(async () => {
  try {
    // 确保项目列表已加载
    if (projectsStore.projects.length === 0) {
      await projectsStore.fetchProjects()
    }
    // 获取所有任务以在日历中显示
    await tasksStore.fetchTasks()
  } catch (error) {
    console.error('加载日历数据失败:', error)
  }
})
</script>
