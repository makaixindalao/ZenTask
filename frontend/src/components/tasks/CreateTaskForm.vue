<template>
  <form @submit.prevent="handleSubmit" class="space-y-6">
    <!-- 任务标题 -->
    <BaseInput
      v-model="form.title"
      label="任务标题"
      placeholder="输入任务标题"
      required
      :error="titleError"
    />
    
    <!-- 任务描述 -->
    <div>
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
        任务描述
      </label>
      <textarea
        v-model="form.description"
        rows="3"
        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-gray-800 dark:text-gray-100 transition-colors duration-200"
        placeholder="输入任务描述（可选）"
        :class="{ 'border-red-300 focus:ring-red-500': descriptionError }"
      ></textarea>
      <p v-if="descriptionError" class="text-sm text-red-600 dark:text-red-400 mt-1">
        {{ descriptionError }}
      </p>
    </div>
    
    <!-- 项目选择 -->
    <div>
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
        项目
      </label>
      <select
        v-model="form.projectId"
        class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-gray-800 dark:text-gray-100 transition-colors duration-200"
        required
      >
        <option value="">选择项目</option>
        <option
          v-for="project in availableProjects"
          :key="project.id"
          :value="project.id"
        >
          {{ project.name }}
        </option>
      </select>
    </div>
    
    <!-- 优先级和截止日期 -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- 优先级 -->
      <div>
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
          优先级
        </label>
        <select
          v-model="form.priority"
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-gray-800 dark:text-gray-100 transition-colors duration-200"
        >
          <option value="low">低</option>
          <option value="medium">中</option>
          <option value="high">高</option>
        </select>
      </div>
      
      <!-- 截止日期 -->
      <BaseInput
        v-model="form.dueDate"
        type="date"
        label="截止日期"
        :error="dueDateError"
      />
    </div>
    
    <!-- 错误信息 -->
    <div v-if="error" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
      <p class="text-red-600 dark:text-red-400 text-sm">{{ error }}</p>
    </div>
    
    <!-- 操作按钮 -->
    <div class="flex justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
      <BaseButton variant="secondary" @click="handleCancel">
        取消
      </BaseButton>
      <BaseButton 
        type="submit" 
        :loading="loading"
        :disabled="!isFormValid"
      >
        创建任务
      </BaseButton>
    </div>
  </form>
</template>

<script setup lang="ts">
import { reactive, ref, computed, onMounted } from 'vue'
import { useProjectsStore } from '@/stores/projects'
import { useTasksStore } from '@/stores/tasks'
import type { CreateTaskRequest, Task, TaskPriority } from '@/types'
import BaseInput from '@/components/common/BaseInput.vue'
import BaseButton from '@/components/common/BaseButton.vue'

interface Props {
  projectId?: number
  dueDate?: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  created: [task: Task]
  cancel: []
}>()

const projectsStore = useProjectsStore()
const tasksStore = useTasksStore()

// 响应式数据
const form = reactive<CreateTaskRequest & { dueDate?: string }>({
  projectId: props.projectId || 0,
  title: '',
  description: '',
  priority: 'medium' as TaskPriority,
  dueDate: props.dueDate || ''
})

const loading = ref(false)
const error = ref('')

// 计算属性
const availableProjects = computed(() => projectsStore.projects)

const titleError = computed(() => {
  if (!form.title.trim()) return ''
  if (form.title.length > 255) return '任务标题不能超过255个字符'
  return ''
})

const descriptionError = computed(() => {
  if (!form.description) return ''
  if (form.description.length > 2000) return '任务描述不能超过2000个字符'
  return ''
})

const dueDateError = computed(() => {
  if (!form.dueDate) return ''
  const selectedDate = new Date(form.dueDate)
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  
  if (selectedDate < today) {
    return '截止日期不能早于今天'
  }
  return ''
})

const isFormValid = computed(() => {
  return (
    form.title.trim() &&
    form.projectId &&
    !titleError.value &&
    !descriptionError.value &&
    !dueDateError.value
  )
})

// 方法
const handleSubmit = async () => {
  if (!isFormValid.value) return
  
  try {
    loading.value = true
    error.value = ''
    
    const taskData: CreateTaskRequest = {
      projectId: form.projectId,
      title: form.title.trim(),
      description: form.description?.trim() || undefined,
      priority: form.priority,
      dueDate: form.dueDate || undefined
    }
    
    const newTask = await tasksStore.createTask(taskData)
    emit('created', newTask)
    
    // 重置表单
    resetForm()
  } catch (err: any) {
    error.value = err.response?.data?.message || '创建任务失败'
  } finally {
    loading.value = false
  }
}

const handleCancel = () => {
  emit('cancel')
}

const resetForm = () => {
  form.title = ''
  form.description = ''
  form.priority = 'medium'
  form.dueDate = props.dueDate || ''
  if (!props.projectId) {
    form.projectId = 0
  }
}

// 生命周期
onMounted(async () => {
  // 确保项目列表已加载
  if (projectsStore.projects.length === 0) {
    try {
      await projectsStore.fetchProjects()
    } catch (error) {
      console.error('加载项目列表失败:', error)
    }
  }

  // 如果没有指定项目ID，默认选择第一个项目
  if (!props.projectId && projectsStore.projects.length > 0) {
    form.projectId = projectsStore.projects[0].id
  }
})
</script>
