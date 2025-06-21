<template>
  <button
    :class="buttonClasses"
    :disabled="disabled || loading"
    @click="handleClick"
  >
    <div v-if="loading" class="animate-spin rounded-full h-4 w-4 border-2 border-current border-t-transparent mr-2"></div>
    <slot />
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  loading?: boolean
  fullWidth?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  disabled: false,
  loading: false,
  fullWidth: false
})

const emit = defineEmits<{
  click: [event: MouseEvent]
}>()

const buttonClasses = computed(() => {
  const baseClasses = [
    'inline-flex items-center justify-center font-medium rounded-lg transition-all duration-200',
    'focus:outline-none focus:ring-2 focus:ring-offset-2',
    'disabled:opacity-50 disabled:cursor-not-allowed'
  ]

  // 尺寸样式
  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-sm',
    lg: 'px-6 py-3 text-base'
  }

  // 变体样式
  const variantClasses = {
    primary: [
      'bg-primary-600 text-white hover:bg-primary-700',
      'focus:ring-primary-500',
      'disabled:hover:bg-primary-600'
    ],
    secondary: [
      'bg-gray-200 text-gray-900 hover:bg-gray-300',
      'dark:bg-gray-700 dark:text-gray-100 dark:hover:bg-gray-600',
      'focus:ring-gray-500'
    ],
    ghost: [
      'bg-transparent text-gray-600 hover:bg-gray-100',
      'dark:text-gray-400 dark:hover:bg-gray-800',
      'focus:ring-gray-500'
    ],
    danger: [
      'bg-red-600 text-white hover:bg-red-700',
      'focus:ring-red-500',
      'disabled:hover:bg-red-600'
    ]
  }

  const widthClasses = props.fullWidth ? 'w-full' : ''

  return [
    ...baseClasses,
    sizeClasses[props.size],
    ...variantClasses[props.variant],
    widthClasses
  ].filter(Boolean).join(' ')
})

const handleClick = (event: MouseEvent) => {
  if (!props.disabled && !props.loading) {
    emit('click', event)
  }
}
</script>
