<template>
  <div
    class="group flex items-center space-x-3 p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-all duration-200 border border-transparent hover:border-gray-200 dark:hover:border-gray-600"
    :class="{ 'opacity-60': task.status === 'completed' }"
  >
    <!-- 完成状态复选框 -->
    <button
      @click="handleToggle"
      class="flex-shrink-0 w-5 h-5 rounded border-2 transition-all duration-200 flex items-center justify-center"
      :class="[
        task.status === 'completed'
          ? 'bg-green-500 border-green-500 text-white'
          : 'border-gray-300 dark:border-gray-600 hover:border-green-400 dark:hover:border-green-500'
      ]"
    >
      <CheckIcon v-if="task.status === 'completed'" class="h-3 w-3" />
    </button>
    
    <!-- 任务内容 -->
    <div class="flex-1 min-w-0 cursor-pointer" @click="handleEdit">
      <!-- 任务标题 -->
      <div
        :class="[
          'text-sm font-medium transition-all duration-200',
          task.status === 'completed'
            ? 'line-through text-gray-500 dark:text-gray-400'
            : 'text-gray-900 dark:text-gray-100'
        ]"
      >
        {{ task.title }}
      </div>
      
      <!-- 任务描述 -->
      <div
        v-if="task.description"
        :class="[
          'text-xs mt-1 truncate transition-all duration-200',
          task.status === 'completed'
            ? 'text-gray-400 dark:text-gray-500'
            : 'text-gray-600 dark:text-gray-400'
        ]"
      >
        {{ task.description }}
      </div>
      
      <!-- 任务元信息 -->
      <div class="flex items-center space-x-2 mt-2">
        <!-- 项目标签 -->
        <span
          v-if="task.project && showProject"
          class="text-xs px-2 py-0.5 rounded-full bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300"
        >
          {{ task.project.name }}
        </span>
        
        <!-- 优先级标签 -->
        <span
          :class="[
            'text-xs px-2 py-0.5 rounded-full font-medium',
            getPriorityClasses(task.priority)
          ]"
        >
          {{ getPriorityLabel(task.priority) }}
        </span>
        
        <!-- 截止日期 -->
        <span
          v-if="task.dueDate"
          :class="[
            'text-xs px-2 py-0.5 rounded-full',
            dueDateClasses
          ]"
        >
          {{ formatDueDate(task.dueDate) }}
        </span>
        
        <!-- 创建时间 -->
        <span class="text-xs text-gray-400 dark:text-gray-500">
          {{ formatRelativeTime(task.createdAt) }}
        </span>
      </div>
    </div>
    
    <!-- 操作按钮 -->
    <div class="flex items-center space-x-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
      <button
        @click="handleEdit"
        class="p-1.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors rounded"
        title="编辑任务"
      >
        <PencilIcon class="h-4 w-4" />
      </button>
      
      <button
        @click="handleDelete"
        class="p-1.5 text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors rounded"
        title="删除任务"
      >
        <TrashIcon class="h-4 w-4" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { CheckIcon, PencilIcon, TrashIcon } from '@heroicons/vue/24/outline'
import { formatDueDate, formatRelativeTime, isToday, isOverdue } from '@/utils/date'
import { PRIORITY_CONFIG } from '@/utils/constants'
import type { Task } from '@/types'

interface Props {
  task: Task
  showProject?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  showProject: false
})

const emit = defineEmits<{
  toggle: [task: Task]
  edit: [task: Task]
  delete: [task: Task]
}>()

// 计算属性
const getPriorityClasses = (priority: string) => {
  switch (priority) {
    case 'high':
      return 'bg-red-100 text-red-700 dark:bg-red-900/50 dark:text-red-300 border border-red-200 dark:border-red-800'
    case 'medium':
      return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-300 border border-yellow-200 dark:border-yellow-800'
    case 'low':
      return 'bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-300 border border-green-200 dark:border-green-800'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-600'
  }
}

const getPriorityLabel = (priority: string) => {
  switch (priority) {
    case 'high':
      return '高优先级'
    case 'medium':
      return '中优先级'
    case 'low':
      return '低优先级'
    default:
      return '普通'
  }
}

const dueDateClasses = computed(() => {
  if (!props.task.dueDate) return ''
  
  if (isOverdue(props.task.dueDate)) {
    return 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'
  } else if (isToday(props.task.dueDate)) {
    return 'bg-orange-100 text-orange-700 dark:bg-orange-900 dark:text-orange-300'
  } else {
    return 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300'
  }
})

// 方法
const handleToggle = () => {
  emit('toggle', props.task)
}

const handleEdit = () => {
  emit('edit', props.task)
}

const handleDelete = () => {
  emit('delete', props.task)
}
</script>
