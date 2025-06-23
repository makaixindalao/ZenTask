<template>
  <span
    :class="[
      'text-xs px-2 py-0.5 rounded-full font-medium',
      priorityClasses
    ]"
  >
    {{ priorityLabel }}
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { TaskPriority } from '@/types'

interface Props {
  priority: TaskPriority
  size?: 'sm' | 'md'
  showIcon?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'sm',
  showIcon: true
})

// 计算属性
const priorityClasses = computed(() => {
  const baseClasses = props.size === 'md' 
    ? 'text-sm px-3 py-1' 
    : 'text-xs px-2 py-0.5'
  
  const colorClasses = (() => {
    switch (props.priority) {
      case 'high':
        return 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'
      case 'medium':
        return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300'
      case 'low':
        return 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300'
      default:
        return 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
    }
  })()
  
  return `${baseClasses} ${colorClasses}`
})

const priorityLabel = computed(() => {
  const icon = props.showIcon ? getPriorityIcon(props.priority) : ''
  const text = getPriorityText(props.priority)
  return props.showIcon ? `${icon} ${text}` : text
})

// 辅助函数
const getPriorityIcon = (priority: TaskPriority): string => {
  switch (priority) {
    case 'high':
      return '🔴'
    case 'medium':
      return '🟡'
    case 'low':
      return '🟢'
    default:
      return '⚪'
  }
}

const getPriorityText = (priority: TaskPriority): string => {
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
</script>
