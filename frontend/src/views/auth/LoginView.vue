<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full">
      <BaseCard padding="lg">
        <!-- 头部 -->
        <div class="text-center mb-8">
          <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
            ZenTask
          </h1>
          <h2 class="text-xl font-semibold text-gray-700 dark:text-gray-300 mb-2">
            欢迎回来
          </h2>
          <p class="text-sm text-gray-600 dark:text-gray-400">
            还没有账户？
            <router-link to="/register" class="font-medium text-primary-600 hover:text-primary-500 transition-colors">
              立即注册
            </router-link>
          </p>
        </div>

        <!-- 登录表单 -->
        <form @submit.prevent="handleLogin" class="space-y-6">
          <BaseInput
            v-model="form.email"
            type="email"
            label="邮箱地址"
            placeholder="请输入邮箱地址"
            required
            :error="emailError"
          />

          <BaseInput
            v-model="form.password"
            type="password"
            label="密码"
            placeholder="请输入密码"
            required
            :error="passwordError"
          />

          <div class="flex items-center">
            <input
              id="remember-me"
              v-model="form.rememberMe"
              type="checkbox"
              class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded dark:border-gray-600 dark:bg-gray-700"
            />
            <label for="remember-me" class="ml-2 block text-sm text-gray-700 dark:text-gray-300">
              记住我（30天）
            </label>
          </div>

          <div v-if="authStore.error" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
            <p class="text-red-600 dark:text-red-400 text-sm">{{ authStore.error }}</p>
          </div>

          <BaseButton
            type="submit"
            :loading="authStore.loading"
            :disabled="!isFormValid"
            full-width
            size="lg"
          >
            登录
          </BaseButton>
        </form>
      </BaseCard>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { LoginRequest } from '@/types'
import BaseCard from '@/components/common/BaseCard.vue'
import BaseInput from '@/components/common/BaseInput.vue'
import BaseButton from '@/components/common/BaseButton.vue'

const router = useRouter()
const authStore = useAuthStore()

const form = reactive<LoginRequest>({
  email: '',
  password: '',
  rememberMe: false
})

// 表单验证
const emailError = computed(() => {
  if (!form.email) return ''
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(form.email) ? '' : '请输入有效的邮箱地址'
})

const passwordError = computed(() => {
  if (!form.password) return ''
  return form.password.length >= 6 ? '' : '密码至少需要6个字符'
})

const isFormValid = computed(() => {
  return form.email && form.password && !emailError.value && !passwordError.value
})

const handleLogin = async () => {
  if (!isFormValid.value) return

  try {
    await authStore.login(form)
    router.push('/today')
  } catch (error) {
    // 错误已在 store 中处理
  }
}

onMounted(() => {
  authStore.clearError()
})
</script>
