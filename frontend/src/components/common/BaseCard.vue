<template>
  <div :class="cardClasses">
    <!-- 头部 -->
    <div v-if="$slots.header || title" :class="headerClasses">
      <slot name="header">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
          {{ title }}
        </h3>
      </slot>
    </div>
    
    <!-- 内容 -->
    <div :class="bodyClasses">
      <slot />
    </div>
    
    <!-- 底部 -->
    <div v-if="$slots.footer" :class="footerClasses">
      <slot name="footer" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  title?: string
  padding?: 'none' | 'sm' | 'md' | 'lg'
  shadow?: 'none' | 'sm' | 'md' | 'lg'
  border?: boolean
  hover?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  padding: 'md',
  shadow: 'sm',
  border: true,
  hover: false
})

const cardClasses = computed(() => {
  const baseClasses = [
    'bg-white dark:bg-gray-800 rounded-lg transition-all duration-200'
  ]

  const shadowClasses = {
    none: '',
    sm: 'shadow-sm',
    md: 'shadow-md',
    lg: 'shadow-lg'
  }

  const borderClasses = props.border 
    ? 'border border-gray-200 dark:border-gray-700'
    : ''

  const hoverClasses = props.hover 
    ? 'hover:shadow-md hover:scale-[1.02] cursor-pointer'
    : ''

  return [
    ...baseClasses,
    shadowClasses[props.shadow],
    borderClasses,
    hoverClasses
  ].filter(Boolean).join(' ')
})

const paddingClasses = computed(() => {
  const classes = {
    none: '',
    sm: 'p-3',
    md: 'p-4',
    lg: 'p-6'
  }
  return classes[props.padding]
})

const headerClasses = computed(() => {
  const base = 'border-b border-gray-200 dark:border-gray-700'
  return `${base} ${paddingClasses.value} pb-3`
})

const bodyClasses = computed(() => {
  const hasHeader = props.title || !!props.$slots?.header
  const hasFooter = !!props.$slots?.footer
  
  let classes = paddingClasses.value
  
  if (hasHeader) {
    classes += ' pt-3'
  }
  
  if (hasFooter) {
    classes += ' pb-3'
  }
  
  return classes
})

const footerClasses = computed(() => {
  const base = 'border-t border-gray-200 dark:border-gray-700'
  return `${base} ${paddingClasses.value} pt-3`
})
</script>
