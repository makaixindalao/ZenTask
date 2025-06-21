<template>
  <button
    @click="toggleTheme"
    class="p-2 rounded-lg text-gray-500 hover:text-gray-700 hover:bg-gray-100 dark:text-gray-400 dark:hover:text-gray-200 dark:hover:bg-gray-800 transition-colors"
    :title="themeTitle"
  >
    <SunIcon v-if="themeStore.mode === 'light'" class="h-5 w-5" />
    <MoonIcon v-else-if="themeStore.mode === 'dark'" class="h-5 w-5" />
    <ComputerDesktopIcon v-else class="h-5 w-5" />
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { SunIcon, MoonIcon, ComputerDesktopIcon } from '@heroicons/vue/24/outline'
import { useThemeStore } from '@/stores/theme'

const themeStore = useThemeStore()

const themeTitle = computed(() => {
  const titles = {
    light: '切换到深色模式',
    dark: '切换到系统模式',
    system: '切换到浅色模式'
  }
  return titles[themeStore.mode]
})

const toggleTheme = () => {
  themeStore.toggleTheme()
}
</script>
