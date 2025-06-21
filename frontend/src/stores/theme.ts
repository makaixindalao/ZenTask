import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import type { ThemeMode } from '@/types'

export const useThemeStore = defineStore('theme', () => {
  // 状态
  const mode = ref<ThemeMode>('system')
  
  // 计算属性
  const isDark = computed(() => {
    if (mode.value === 'dark') return true
    if (mode.value === 'light') return false
    
    // 系统模式：检查系统偏好
    return window.matchMedia('(prefers-color-scheme: dark)').matches
  })

  // 动作
  const setTheme = (newMode: ThemeMode): void => {
    mode.value = newMode
    localStorage.setItem('theme', newMode)
    updateDocumentClass()
  }

  const toggleTheme = (): void => {
    if (mode.value === 'light') {
      setTheme('dark')
    } else if (mode.value === 'dark') {
      setTheme('system')
    } else {
      setTheme('light')
    }
  }

  const updateDocumentClass = (): void => {
    const html = document.documentElement
    
    if (isDark.value) {
      html.classList.add('dark')
    } else {
      html.classList.remove('dark')
    }
  }

  const initializeTheme = (): void => {
    // 从本地存储读取主题设置
    const storedTheme = localStorage.getItem('theme') as ThemeMode
    if (storedTheme && ['light', 'dark', 'system'].includes(storedTheme)) {
      mode.value = storedTheme
    }
    
    updateDocumentClass()
    
    // 监听系统主题变化
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    mediaQuery.addEventListener('change', updateDocumentClass)
  }

  // 监听主题变化
  watch(isDark, updateDocumentClass)

  return {
    // 状态
    mode,
    // 计算属性
    isDark,
    // 动作
    setTheme,
    toggleTheme,
    initializeTheme
  }
})
