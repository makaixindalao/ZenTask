<template>
  <BaseModal
    :show="show"
    title="编辑任务"
    size="lg"
    @close="handleClose"
  >
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
          rows="4"
          class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-gray-800 dark:text-gray-100 transition-colors duration-200"
          placeholder="输入任务描述（可选）"
          :class="{ 'border-red-300 focus:ring-red-500': descriptionError }"
        ></textarea>
        <p v-if="descriptionError" class="text-sm text-red-600 dark:text-red-400 mt-1">
          {{ descriptionError }}
        </p>
      </div>
      
      <!-- 状态和优先级 -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- 任务状态 -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            状态
          </label>
          <select
            v-model="form.status"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-gray-800 dark:text-gray-100 transition-colors duration-200"
          >
            <option value="pending">待完成</option>
            <option value="completed">已完成</option>
          </select>
        </div>
        
        <!-- 优先级 -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
            优先级
          </label>
          <select
            v-model="form.priority"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent dark:bg-gray-800 dark:text-gray-100 transition-colors duration-200"
          >
            <option value="low">低优先级</option>
            <option value="medium">中优先级</option>
            <option value="high">高优先级</option>
          </select>
        </div>
      </div>
      
      <!-- 截止日期 -->
      <BaseInput
        v-model="form.dueDate"
        type="date"
        label="截止日期"
        :error="dueDateError"
      />
      
      <!-- 任务信息 -->
      <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 space-y-2">
        <h4 class="text-sm font-medium text-gray-900 dark:text-gray-100">任务信息</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div>
            <span class="text-gray-600 dark:text-gray-400">所属项目：</span>
            <span class="text-gray-900 dark:text-gray-100">{{ task?.project?.name }}</span>
          </div>
          <div>
            <span class="text-gray-600 dark:text-gray-400">创建时间：</span>
            <span class="text-gray-900 dark:text-gray-100">{{ formatDateTime(task?.createdAt) }}</span>
          </div>
          <div>
            <span class="text-gray-600 dark:text-gray-400">最后更新：</span>
            <span class="text-gray-900 dark:text-gray-100">{{ formatDateTime(task?.updatedAt) }}</span>
          </div>
          <div v-if="task?.status === 'completed'">
            <span class="text-gray-600 dark:text-gray-400">完成时间：</span>
            <span class="text-green-600 dark:text-green-400">{{ formatDateTime(task?.updatedAt) }}</span>
          </div>
        </div>
      </div>
      
      <!-- 错误信息 -->
      <div v-if="error" class="p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
        <p class="text-red-600 dark:text-red-400 text-sm">{{ error }}</p>
      </div>
    </form>
    
    <template #footer>
      <div class="flex justify-between w-full">
        <BaseButton
          variant="danger"
          @click="handleDelete"
          :loading="deleting"
        >
          删除任务
        </BaseButton>
        
        <div class="flex space-x-3">
          <BaseButton variant="secondary" @click="handleClose">
            取消
          </BaseButton>
          <BaseButton 
            @click="handleSubmit"
            :loading="loading"
            :disabled="!isFormValid"
          >
            保存更改
          </BaseButton>
        </div>
      </div>
    </template>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { useTasksStore } from '@/stores/tasks'
import { formatDateTime } from '@/utils/date'
import type { Task, UpdateTaskRequest, TaskStatus, TaskPriority } from '@/types'
import BaseModal from '@/components/common/BaseModal.vue'
import BaseInput from '@/components/common/BaseInput.vue'
import BaseButton from '@/components/common/BaseButton.vue'

interface Props {
  show: boolean
  task: Task | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  close: []
  updated: [task: Task]
  deleted: [taskId: number]
}>()

const tasksStore = useTasksStore()

// 响应式数据
const form = reactive<{
  title: string
  description: string
  status: TaskStatus
  priority: TaskPriority
  dueDate: string
}>({
  title: '',
  description: '',
  status: 'pending',
  priority: 'medium',
  dueDate: ''
})

const loading = ref(false)
const deleting = ref(false)
const error = ref('')

// 计算属性
const titleError = computed(() => {
  if (!form.title.trim()) return '任务标题不能为空'
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
    !titleError.value &&
    !descriptionError.value &&
    !dueDateError.value
  )
})

// 监听任务变化，更新表单
watch(() => props.task, (newTask) => {
  if (newTask) {
    form.title = newTask.title
    form.description = newTask.description || ''
    form.status = newTask.status
    form.priority = newTask.priority
    form.dueDate = newTask.dueDate ? newTask.dueDate.split('T')[0] : ''
  }
}, { immediate: true })

// 监听显示状态，重置错误
watch(() => props.show, (show) => {
  if (show) {
    error.value = ''
  }
})

// 方法
const handleSubmit = async () => {
  if (!props.task || !isFormValid.value) return
  
  try {
    loading.value = true
    error.value = ''
    
    const updateData: UpdateTaskRequest = {
      title: form.title.trim(),
      description: form.description.trim() || undefined,
      status: form.status,
      priority: form.priority,
      dueDate: form.dueDate || undefined
    }
    
    const updatedTask = await tasksStore.updateTask(props.task.id, updateData)
    
    emit('updated', updatedTask)
    emit('close')
  } catch (err: any) {
    error.value = err.response?.data?.message || '更新任务失败'
  } finally {
    loading.value = false
  }
}

const handleDelete = async () => {
  if (!props.task) return
  
  const confirmed = confirm(`确定要删除任务"${props.task.title}"吗？\n\n此操作无法撤销。`)
  
  if (!confirmed) return
  
  try {
    deleting.value = true
    error.value = ''
    
    await tasksStore.deleteTask(props.task.id)
    
    emit('deleted', props.task.id)
    emit('close')
  } catch (err: any) {
    error.value = err.response?.data?.message || '删除任务失败'
  } finally {
    deleting.value = false
  }
}

const handleClose = () => {
  emit('close')
}
</script>
