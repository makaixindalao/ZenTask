<template>
  <span
    v-if="variant === 'badge'"
    :class="[
      'inline-flex items-center gap-1 text-xs font-medium rounded-full border transition-colors duration-200',
      sizeClasses,
      priorityClasses
    ]"
    :title="priorityTooltip"
  >
    <component :is="priorityIcon" v-if="showIcon" class="flex-shrink-0" :class="iconSizeClasses" />
    <span v-if="showText">{{ priorityText }}</span>
  </span>

  <span
    v-else-if="variant === 'compact'"
    :class="[
      'inline-flex items-center gap-1 text-xs font-medium px-1.5 py-0.5 rounded border transition-colors duration-200',
      compactClasses
    ]"
    :title="priorityTooltip"
  >
    <component :is="priorityIcon" class="flex-shrink-0" :class="compactIconSizeClasses" />
    <span>{{ priorityText }}</span>
  </span>

  <span
    v-else-if="variant === 'dot'"
    :class="[
      'inline-flex items-center gap-1.5 text-xs text-gray-600 dark:text-gray-400'
    ]"
    :title="priorityTooltip"
  >
    <span :class="['w-2 h-2 rounded-full flex-shrink-0', dotColorClasses]"></span>
    <span v-if="showText">{{ priorityText }}</span>
  </span>

  <span
    v-else
    :class="[
      'inline-flex items-center gap-1 text-xs',
      minimalClasses
    ]"
    :title="priorityTooltip"
  >
    <component :is="priorityIcon" v-if="showIcon" class="flex-shrink-0" :class="iconSizeClasses" />
    <span v-if="showText">{{ priorityText }}</span>
  </span>
</template>

<script setup lang="ts">
import { computed, h } from 'vue'
import type { TaskPriority } from '@/types'

interface Props {
  priority: TaskPriority
  size?: 'xs' | 'sm' | 'md'
  variant?: 'badge' | 'compact' | 'dot' | 'minimal'
  showIcon?: boolean
  showText?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'sm',
  variant: 'compact',
  showIcon: true,
  showText: true
})

// 计算属性
const sizeClasses = computed(() => {
  const classes = {
    xs: 'px-1.5 py-0.5 text-xs',
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-1 text-sm'
  }
  return classes[props.size]
})

const iconSizeClasses = computed(() => {
  const classes = {
    xs: 'w-2.5 h-2.5',
    sm: 'w-3 h-3',
    md: 'w-3.5 h-3.5'
  }
  return classes[props.size]
})

const compactIconSizeClasses = computed(() => {
  return 'w-2.5 h-2.5' // 固定尺寸，保持紧凑
})

const priorityClasses = computed(() => {
  switch (props.priority) {
    case 'high':
      return 'bg-red-50 text-red-700 border-red-200 dark:bg-red-950 dark:text-red-300 dark:border-red-800'
    case 'medium':
      return 'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950 dark:text-amber-300 dark:border-amber-800'
    case 'low':
      return 'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950 dark:text-emerald-300 dark:border-emerald-800'
    default:
      return 'bg-gray-50 text-gray-600 border-gray-200 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-700'
  }
})

const compactClasses = computed(() => {
  switch (props.priority) {
    case 'high':
      return 'bg-red-50 text-red-700 border-red-200 dark:bg-red-950/50 dark:text-red-300 dark:border-red-800/50'
    case 'medium':
      return 'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/50 dark:text-amber-300 dark:border-amber-800/50'
    case 'low':
      return 'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/50 dark:text-emerald-300 dark:border-emerald-800/50'
    default:
      return 'bg-gray-50 text-gray-600 border-gray-200 dark:bg-gray-800/50 dark:text-gray-400 dark:border-gray-700/50'
  }
})

const dotColorClasses = computed(() => {
  switch (props.priority) {
    case 'high':
      return 'bg-red-500'
    case 'medium':
      return 'bg-amber-500'
    case 'low':
      return 'bg-emerald-500'
    default:
      return 'bg-gray-400'
  }
})

const minimalClasses = computed(() => {
  switch (props.priority) {
    case 'high':
      return 'text-red-600 dark:text-red-400'
    case 'medium':
      return 'text-amber-600 dark:text-amber-400'
    case 'low':
      return 'text-emerald-600 dark:text-emerald-400'
    default:
      return 'text-gray-500 dark:text-gray-400'
  }
})

const priorityText = computed(() => {
  switch (props.priority) {
    case 'high':
      return '高'
    case 'medium':
      return '中'
    case 'low':
      return '低'
    default:
      return '普通'
  }
})

const priorityTooltip = computed(() => {
  switch (props.priority) {
    case 'high':
      return '高优先级'
    case 'medium':
      return '中优先级'
    case 'low':
      return '低优先级'
    default:
      return '普通优先级'
  }
})

// 优先级图标组件
const priorityIcon = computed(() => {
  const createIcon = (paths: string[]) => {
    return h('svg', {
      viewBox: '0 0 16 16',
      fill: 'currentColor',
      class: 'inline-block'
    }, paths.map(path => h('path', { d: path })))
  }

  switch (props.priority) {
    case 'high':
      // 向上箭头
      return createIcon([
        'M8 2L3 7h3v6h4V7h3L8 2z'
      ])
    case 'medium':
      // 水平线
      return createIcon([
        'M3 8h10v1H3V8z'
      ])
    case 'low':
      // 向下箭头
      return createIcon([
        'M8 14l5-5h-3V3H6v6H3l5 5z'
      ])
    default:
      // 圆点
      return createIcon([
        'M8 10a2 2 0 100-4 2 2 0 000 4z'
      ])
  }
})
</script>
