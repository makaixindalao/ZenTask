import api from './index'
import type { LoginRequest, RegisterRequest, AuthResponse } from '@/types'

export const authApi = {
  // 用户登录
  login: async (credentials: LoginRequest): Promise<AuthResponse> => {
    return await api.post('/auth/login', credentials)
  },

  // 用户注册
  register: async (credentials: RegisterRequest): Promise<AuthResponse> => {
    return await api.post('/auth/register', credentials)
  },

  // 验证 token
  verifyToken: async (): Promise<{ valid: boolean }> => {
    return await api.get('/auth/verify')
  },
}
