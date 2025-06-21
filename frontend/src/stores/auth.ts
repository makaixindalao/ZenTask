import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User, LoginRequest, RegisterRequest, AuthResponse } from '@/types'
import { authApi } from '@/api/auth'

export const useAuthStore = defineStore('auth', () => {
  // 状态
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('token'))
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 计算属性
  const isAuthenticated = computed(() => !!token.value && !!user.value)

  // 动作
  const login = async (credentials: LoginRequest): Promise<void> => {
    try {
      loading.value = true
      error.value = null
      
      const response = await authApi.login(credentials)
      
      user.value = response.user
      token.value = response.token
      
      // 存储到本地存储
      localStorage.setItem('token', response.token)
      localStorage.setItem('user', JSON.stringify(response.user))
      
    } catch (err: any) {
      error.value = err.response?.data?.message || '登录失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const register = async (credentials: RegisterRequest): Promise<void> => {
    try {
      loading.value = true
      error.value = null
      
      const response = await authApi.register(credentials)
      
      user.value = response.user
      token.value = response.token
      
      // 存储到本地存储
      localStorage.setItem('token', response.token)
      localStorage.setItem('user', JSON.stringify(response.user))
      
    } catch (err: any) {
      error.value = err.response?.data?.message || '注册失败'
      throw err
    } finally {
      loading.value = false
    }
  }

  const logout = (): void => {
    user.value = null
    token.value = null
    
    // 清除本地存储
    localStorage.removeItem('token')
    localStorage.removeItem('user')
  }

  const initializeAuth = (): void => {
    const storedToken = localStorage.getItem('token')
    const storedUser = localStorage.getItem('user')
    
    if (storedToken && storedUser) {
      try {
        token.value = storedToken
        user.value = JSON.parse(storedUser)
      } catch (err) {
        // 如果解析失败，清除存储
        logout()
      }
    }
  }

  const clearError = (): void => {
    error.value = null
  }

  return {
    // 状态
    user,
    token,
    loading,
    error,
    // 计算属性
    isAuthenticated,
    // 动作
    login,
    register,
    logout,
    initializeAuth,
    clearError
  }
})
