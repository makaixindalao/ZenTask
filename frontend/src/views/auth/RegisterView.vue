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
            创建账户
          </h2>
          <p class="text-sm text-gray-600 dark:text-gray-400">
            已有账户？
            <router-link to="/login" class="font-medium text-primary-600 hover:text-primary-500 transition-colors">
              立即登录
            </router-link>
          </p>
        </div>
        
        <!-- 注册表单 -->
        <form @submit.prevent="handleRegister" class="space-y-6">
          <BaseInput
            v-model="form.email"
            type="email"
            label="邮箱地址"
            placeholder="请输入邮箱地址"
            required
            :error="emailError"
            hint="我们将使用此邮箱地址作为您的登录账户"
          />
          
          <BaseInput
            v-model="form.password"
            type="password"
            label="密码"
            placeholder="请输入密码"
            required
            :error="passwordError"
            hint="密码至少需要6个字符"
          />
          
          <BaseInput
            v-model="confirmPassword"
            type="password"
            label="确认密码"
            placeholder="请再次输入密码"
            required
            :error="confirmPasswordError"
          />

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
            创建账户
          </BaseButton>
        </form>
        
        <!-- 服务条款 -->
        <div class="mt-6 text-center">
          <p class="text-xs text-gray-500 dark:text-gray-400">
            注册即表示您同意我们的
            <a href="#" class="text-primary-600 hover:text-primary-500">服务条款</a>
            和
            <a href="#" class="text-primary-600 hover:text-primary-500">隐私政策</a>
          </p>
        </div>
      </BaseCard>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import type { RegisterRequest } from '@/types'
import BaseCard from '@/components/common/BaseCard.vue'
import BaseInput from '@/components/common/BaseInput.vue'
import BaseButton from '@/components/common/BaseButton.vue'

const router = useRouter()
const authStore = useAuthStore()

const form = reactive<RegisterRequest>({
  email: '',
  password: ''
})

const confirmPassword = ref('')

// 表单验证
const emailError = computed(() => {
  if (!form.email) return ''
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(form.email) ? '' : '请输入有效的邮箱地址'
})

const passwordError = computed(() => {
  if (!form.password) return ''
  if (form.password.length < 6) return '密码至少需要6个字符'
  if (form.password.length > 128) return '密码不能超过128个字符'
  return ''
})

const confirmPasswordError = computed(() => {
  if (!confirmPassword.value) return ''
  return confirmPassword.value === form.password ? '' : '两次输入的密码不一致'
})

const isFormValid = computed(() => {
  return (
    form.email &&
    form.password &&
    confirmPassword.value &&
    !emailError.value &&
    !passwordError.value &&
    !confirmPasswordError.value
  )
})

const handleRegister = async () => {
  if (!isFormValid.value) return
  
  try {
    await authStore.register(form)
    router.push('/dashboard')
  } catch (error) {
    // 错误已在 store 中处理
  }
}

onMounted(() => {
  authStore.clearError()
})
</script>
