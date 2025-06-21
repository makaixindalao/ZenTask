<template>
  <div :class="containerClasses">
    <div :class="spinnerClasses">
      <div class="animate-spin rounded-full border-2 border-current border-t-transparent"></div>
    </div>
    <p v-if="text" :class="textClasses">{{ text }}</p>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  size?: 'sm' | 'md' | 'lg' | 'xl'
  text?: string
  center?: boolean
  overlay?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  center: false,
  overlay: false
})

const containerClasses = computed(() => {
  const baseClasses = ['flex flex-col items-center space-y-2']
  
  if (props.center) {
    baseClasses.push('justify-center min-h-[200px]')
  }
  
  if (props.overlay) {
    baseClasses.push(
      'fixed inset-0 z-50 bg-white/80 dark:bg-gray-900/80',
      'backdrop-blur-sm justify-center items-center'
    )
  }
  
  return baseClasses.join(' ')
})

const spinnerClasses = computed(() => {
  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-6 w-6',
    lg: 'h-8 w-8',
    xl: 'h-12 w-12'
  }
  
  return `${sizeClasses[props.size]} text-primary-600`
})

const textClasses = computed(() => {
  const sizeClasses = {
    sm: 'text-xs',
    md: 'text-sm',
    lg: 'text-base',
    xl: 'text-lg'
  }
  
  return `${sizeClasses[props.size]} text-gray-600 dark:text-gray-400`
})
</script>
