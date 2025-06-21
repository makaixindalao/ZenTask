<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
    <!-- 主布局容器 -->
    <div class="flex h-screen">
      <!-- 侧边栏 -->
      <AppSidebar />

      <!-- 主内容区域 -->
      <main class="flex-1 overflow-hidden">
        <div class="h-full flex flex-col">
          <!-- 头部工具栏 -->
          <header class="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 px-6 py-4">
            <div class="flex items-center justify-between">
              <div>
                <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                  收件箱
                </h1>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  管理您的所有任务
                </p>
              </div>

              <div class="flex items-center space-x-3">
                <!-- 视图切换 -->
                <div class="flex items-center bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
                  <button
                    :class="[
                      'px-3 py-1 text-sm font-medium rounded-md transition-colors',
                      viewMode === 'list'
                        ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-gray-100 shadow-sm'
                        : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'
                    ]"
                    @click="viewMode = 'list'"
                  >
                    列表
                  </button>
                  <button
                    :class="[
                      'px-3 py-1 text-sm font-medium rounded-md transition-colors',
                      viewMode === 'board'
                        ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-gray-100 shadow-sm'
                        : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100'
                    ]"
                    @click="viewMode = 'board'"
                  >
                    看板
                  </button>
                </div>

                <!-- 添加任务按钮 -->
                <BaseButton @click="showCreateTask = true">
                  <PlusIcon class="h-4 w-4 mr-2" />
                  添加任务
                </BaseButton>
              </div>
            </div>
          </header>

          <!-- 任务列表区域 -->
          <div class="flex-1 overflow-hidden">
            <div class="h-full p-6">
              <LoadingSpinner v-if="tasksStore.loading" center text="加载任务中..." />

              <div v-else-if="tasks.length === 0" class="flex flex-col items-center justify-center h-full text-center">
                <div class="w-24 h-24 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4">
                  <InboxIcon class="h-12 w-12 text-gray-400" />
                </div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
                  收件箱为空
                </h3>
                <p class="text-gray-600 dark:text-gray-400 mb-6 max-w-sm">
                  开始添加任务来组织您的工作。所有新任务都会出现在这里。
                </p>
                <BaseButton @click="showCreateTask = true">
                  <PlusIcon class="h-4 w-4 mr-2" />
                  创建第一个任务
                </BaseButton>
              </div>

              <div v-else class="space-y-3">
                <!-- 任务筛选和排序 -->
                <div class="flex items-center justify-between mb-4">
                  <div class="flex items-center space-x-4">
                    <select
                      v-model="filterStatus"
                      class="text-sm border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
                    >
                      <option value="all">全部任务</option>
                      <option value="pending">未完成</option>
                      <option value="completed">已完成</option>
                    </select>

                    <select
                      v-model="sortBy"
                      class="text-sm border border-gray-300 dark:border-gray-600 rounded-lg px-3 py-1 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
                    >
                      <option value="sortOrder">自定义排序</option>
                      <option value="createdAt">创建时间</option>
                      <option value="dueDate">截止日期</option>
                      <option value="priority">优先级</option>
                    </select>
                  </div>

                  <div class="text-sm text-gray-600 dark:text-gray-400">
                    共 {{ filteredTasks.length }} 个任务
                  </div>
                </div>

                <!-- 任务列表 -->
                <div class="space-y-2">
                  <TaskItem
                    v-for="task in filteredTasks"
                    :key="task.id"
                    :task="task"
                    show-project
                    @toggle="handleToggleTask"
                    @edit="handleEditTask"
                    @delete="handleDeleteTask"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>

    <!-- 创建任务模态框 -->
    <BaseModal
      :show="showCreateTask"
      title="创建新任务"
      size="lg"
      @close="showCreateTask = false"
    >
      <CreateTaskForm
        :project-id="inboxProjectId"
        @created="handleTaskCreated"
        @cancel="showCreateTask = false"
      />
    </BaseModal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { PlusIcon, InboxIcon } from '@heroicons/vue/24/outline'
import { useProjectsStore } from '@/stores/projects'
import { useTasksStore } from '@/stores/tasks'
import type { Task } from '@/types'

import AppSidebar from '@/components/layout/AppSidebar.vue'
import BaseButton from '@/components/common/BaseButton.vue'
import BaseModal from '@/components/common/BaseModal.vue'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'
import TaskItem from '@/components/tasks/TaskItem.vue'
import CreateTaskForm from '@/components/tasks/CreateTaskForm.vue'

const projectsStore = useProjectsStore()
const tasksStore = useTasksStore()

// 响应式数据
const viewMode = ref<'list' | 'board'>('list')
const filterStatus = ref<'all' | 'pending' | 'completed'>('all')
const sortBy = ref<'sortOrder' | 'createdAt' | 'dueDate' | 'priority'>('sortOrder')
const showCreateTask = ref(false)

// 计算属性
const inboxProjectId = computed(() => projectsStore.inboxProject?.id)

const tasks = computed(() => tasksStore.tasks)

const filteredTasks = computed(() => {
  let filtered = tasks.value

  // 状态筛选
  if (filterStatus.value !== 'all') {
    filtered = filtered.filter(task => task.status === filterStatus.value)
  }

  // 排序
  filtered = [...filtered].sort((a, b) => {
    switch (sortBy.value) {
      case 'createdAt':
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      case 'dueDate':
        if (!a.dueDate && !b.dueDate) return 0
        if (!a.dueDate) return 1
        if (!b.dueDate) return -1
        return new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime()
      case 'priority':
        const priorityOrder = { high: 3, medium: 2, low: 1 }
        return priorityOrder[b.priority] - priorityOrder[a.priority]
      case 'sortOrder':
      default:
        return a.sortOrder - b.sortOrder
    }
  })

  return filtered
})

// 方法
const handleToggleTask = async (task: Task) => {
  try {
    await tasksStore.toggleTaskStatus(task.id)
  } catch (error) {
    console.error('切换任务状态失败:', error)
  }
}

const handleEditTask = (task: Task) => {
  tasksStore.setCurrentTask(task)
  // TODO: 打开编辑任务模态框
}

const handleDeleteTask = async (task: Task) => {
  if (confirm('确定要删除这个任务吗？')) {
    try {
      await tasksStore.deleteTask(task.id)
    } catch (error) {
      console.error('删除任务失败:', error)
    }
  }
}

const handleTaskCreated = (task: Task) => {
  showCreateTask.value = false
  // 任务已在 store 中添加
}

// 生命周期
onMounted(async () => {
  try {
    if (inboxProjectId.value) {
      await tasksStore.fetchTasks({ projectId: inboxProjectId.value })
    }
  } catch (error) {
    console.error('加载收件箱任务失败:', error)
  }
})
</script>
