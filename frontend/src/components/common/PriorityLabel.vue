<template>
  <!-- 徽章样式 - 完整的优先级标签 -->
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

  <!-- 紧凑样式 - 与日期标签一致的圆角矩形样式 -->
  <span
    v-else-if="variant === 'compact'"
    :class="[
      'text-xs px-2 py-0.5 rounded-full transition-colors duration-200',
      compactClasses
    ]"
    :title="priorityTooltip"
  >
    {{ priorityText }}
  </span>

  <!-- 圆点样式 - 仅显示颜色圆点 -->
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

  <!-- 图标样式 - 仅显示图标 -->
  <span
    v-else-if="variant === 'icon'"
    :class="[
      'inline-flex items-center gap-1 text-xs transition-colors duration-200',
      iconOnlyClasses
    ]"
    :title="priorityTooltip"
  >
    <component :is="priorityIcon" class="flex-shrink-0" :class="iconSizeClasses" />
    <span v-if="showText">{{ priorityText }}</span>
  </span>

  <!-- 最小样式 - 纯文字 -->
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
  variant?: 'badge' | 'compact' | 'dot' | 'icon' | 'minimal'
  showIcon?: boolean
  showText?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'sm',
  variant: 'badge',
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

// 紧凑样式类 - 与日期标签保持一致的样式
const compactClasses = computed(() => {
  switch (props.priority) {
    case 'high':
      return 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'
    case 'medium':
      return 'bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-300'
    case 'low':
      return 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900 dark:text-emerald-300'
    default:
      return 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
  }
})

// 仅图标样式类
const iconOnlyClasses = computed(() => {
  switch (props.priority) {
    case 'high':
      return 'text-red-500 dark:text-red-400'
    case 'medium':
      return 'text-amber-500 dark:text-amber-400'
    case 'low':
      return 'text-emerald-500 dark:text-emerald-400'
    default:
      return 'text-gray-400 dark:text-gray-500'
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
