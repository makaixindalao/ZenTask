<template>
  <BaseModal
    :show="show"
    title="编辑项目"
    @close="handleClose"
  >
    <form @submit.prevent="handleSubmit">
      <div class="space-y-4">
        <BaseInput
          v-model="form.name"
          label="项目名称"
          placeholder="输入项目名称"
          required
          :error="nameError"
        />
      </div>
      
      <div v-if="error" class="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
        <p class="text-red-600 dark:text-red-400 text-sm">{{ error }}</p>
      </div>
      
      <template #footer>
        <div class="flex justify-between w-full">
          <BaseButton
            v-if="project && !project.isInbox"
            variant="danger"
            @click="handleDelete"
            :loading="deleting"
          >
            删除项目
          </BaseButton>
          
          <div class="flex space-x-3 ml-auto">
            <BaseButton variant="secondary" @click="handleClose">
              取消
            </BaseButton>
            <BaseButton 
              type="submit" 
              :loading="loading"
              :disabled="!isFormValid"
            >
              保存
            </BaseButton>
          </div>
        </div>
      </template>
    </form>
  </BaseModal>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { useProjectsStore } from '@/stores/projects'
import type { Project } from '@/types'
import BaseModal from '@/components/common/BaseModal.vue'
import BaseInput from '@/components/common/BaseInput.vue'
import BaseButton from '@/components/common/BaseButton.vue'

interface Props {
  show: boolean
  project: Project | null
}

const props = defineProps<Props>()

const emit = defineEmits<{
  close: []
  updated: [project: Project]
  deleted: [projectId: number]
}>()

const projectsStore = useProjectsStore()

// 响应式数据
const form = reactive({
  name: ''
})

const loading = ref(false)
const deleting = ref(false)
const error = ref('')

// 计算属性
const nameError = computed(() => {
  if (!form.name.trim()) return '项目名称不能为空'
  if (form.name.length > 100) return '项目名称不能超过100个字符'
  return ''
})

const isFormValid = computed(() => {
  return form.name.trim() && !nameError.value
})

// 监听项目变化，更新表单
watch(() => props.project, (newProject) => {
  if (newProject) {
    form.name = newProject.name
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
  if (!props.project || !isFormValid.value) return
  
  try {
    loading.value = true
    error.value = ''
    
    const updatedProject = await projectsStore.updateProject(props.project.id, {
      name: form.name.trim()
    })
    
    emit('updated', updatedProject)
    emit('close')
  } catch (err: any) {
    error.value = err.response?.data?.message || '更新项目失败'
  } finally {
    loading.value = false
  }
}

const handleDelete = async () => {
  if (!props.project || props.project.isInbox) return
  
  const confirmed = confirm(`确定要删除项目"${props.project.name}"吗？\n\n删除后，该项目下的所有任务也将被删除，此操作无法撤销。`)
  
  if (!confirmed) return
  
  try {
    deleting.value = true
    error.value = ''
    
    await projectsStore.deleteProject(props.project.id)
    
    emit('deleted', props.project.id)
    emit('close')
  } catch (err: any) {
    error.value = err.response?.data?.message || '删除项目失败'
  } finally {
    deleting.value = false
  }
}

const handleClose = () => {
  emit('close')
}
</script>
