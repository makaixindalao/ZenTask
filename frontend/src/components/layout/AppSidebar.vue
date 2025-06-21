<template>
  <aside class="w-64 sidebar flex flex-col h-full">
    <!-- 头部 -->
    <div class="p-4 border-b border-gray-200 dark:border-gray-700">
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-bold text-gray-900 dark:text-gray-100">ZenTask</h1>
        <ThemeToggle />
      </div>
    </div>
    
    <!-- 导航菜单 -->
    <nav class="flex-1 p-4 space-y-2 overflow-y-auto scrollbar-thin">
      <!-- 智能视图 -->
      <div class="space-y-1">
        <router-link
          to="/dashboard"
          class="nav-link"
          :class="{ 'nav-link-active': $route.name === 'dashboard' }"
        >
          <InboxIcon class="h-5 w-5" />
          <span>收件箱</span>
          <span v-if="inboxCount > 0" class="task-count">{{ inboxCount }}</span>
        </router-link>
        
        <router-link
          to="/today"
          class="nav-link"
          :class="{ 'nav-link-active': $route.name === 'today' }"
        >
          <CalendarDaysIcon class="h-5 w-5" />
          <span>今天</span>
          <span v-if="todayCount > 0" class="task-count">{{ todayCount }}</span>
        </router-link>
        
        <router-link
          to="/upcoming"
          class="nav-link"
          :class="{ 'nav-link-active': $route.name === 'upcoming' }"
        >
          <ClockIcon class="h-5 w-5" />
          <span>最近7天</span>
          <span v-if="upcomingCount > 0" class="task-count">{{ upcomingCount }}</span>
        </router-link>
      </div>
      
      <!-- 项目列表 -->
      <div class="mt-6">
        <div class="flex items-center justify-between mb-2">
          <h3 class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
            项目
          </h3>
          <button
            @click="showCreateProject = true"
            class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
            title="新建项目"
          >
            <PlusIcon class="h-4 w-4" />
          </button>
        </div>
        
        <div class="space-y-1">
          <div
            v-for="project in customProjects"
            :key="project.id"
            class="group relative"
          >
            <router-link
              :to="`/project/${project.id}`"
              class="nav-link"
              :class="{ 'nav-link-active': $route.params.id == project.id }"
            >
              <FolderIcon class="h-5 w-5" />
              <span class="truncate">{{ project.name }}</span>
              <span v-if="project.uncompletedTaskCount > 0" class="task-count">
                {{ project.uncompletedTaskCount }}
              </span>
            </router-link>
            
            <!-- 项目操作按钮 -->
            <div class="absolute right-2 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
              <button
                @click.prevent="editProject(project)"
                class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                title="编辑项目"
              >
                <PencilIcon class="h-3 w-3" />
              </button>
            </div>
          </div>
          
          <div v-if="customProjects.length === 0" class="text-sm text-gray-500 dark:text-gray-400 py-2">
            暂无项目
          </div>
        </div>
      </div>
    </nav>
    
    <!-- 用户菜单 -->
    <div class="p-4 border-t border-gray-200 dark:border-gray-700">
      <div class="flex items-center justify-between">
        <div class="flex items-center space-x-2">
          <div class="h-8 w-8 bg-primary-600 rounded-full flex items-center justify-center">
            <span class="text-white text-sm font-medium">
              {{ userInitial }}
            </span>
          </div>
          <span class="text-sm text-gray-700 dark:text-gray-300 truncate">
            {{ authStore.user?.email }}
          </span>
        </div>
        <button
          @click="handleLogout"
          class="p-1 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
          title="退出登录"
        >
          <ArrowRightOnRectangleIcon class="h-5 w-5" />
        </button>
      </div>
    </div>
    
    <!-- 创建项目模态框 -->
    <BaseModal
      :show="showCreateProject"
      title="新建项目"
      @close="showCreateProject = false"
    >
      <form @submit.prevent="handleCreateProject">
        <BaseInput
          v-model="newProjectName"
          label="项目名称"
          placeholder="输入项目名称"
          required
          :error="createProjectError"
        />

        <template #footer>
          <BaseButton variant="secondary" @click="showCreateProject = false">
            取消
          </BaseButton>
          <BaseButton type="submit" :loading="projectsStore.loading">
            创建
          </BaseButton>
        </template>
      </form>
    </BaseModal>

    <!-- 编辑项目模态框 -->
    <EditProjectModal
      :show="showEditProject"
      :project="editingProject"
      @close="showEditProject = false"
      @updated="handleProjectUpdated"
      @deleted="handleProjectDeleted"
    />
  </aside>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  InboxIcon,
  CalendarDaysIcon,
  ClockIcon,
  FolderIcon,
  PlusIcon,
  PencilIcon,
  ArrowRightOnRectangleIcon
} from '@heroicons/vue/24/outline'

import { useAuthStore } from '@/stores/auth'
import { useProjectsStore } from '@/stores/projects'
import { useTasksStore } from '@/stores/tasks'
import type { Project } from '@/types'
import ThemeToggle from '@/components/common/ThemeToggle.vue'
import BaseModal from '@/components/common/BaseModal.vue'
import BaseInput from '@/components/common/BaseInput.vue'
import BaseButton from '@/components/common/BaseButton.vue'
import EditProjectModal from '@/components/projects/EditProjectModal.vue'

const router = useRouter()
const authStore = useAuthStore()
const projectsStore = useProjectsStore()
const tasksStore = useTasksStore()

// 响应式数据
const showCreateProject = ref(false)
const showEditProject = ref(false)
const newProjectName = ref('')
const createProjectError = ref('')
const editingProject = ref<Project | null>(null)

// 计算属性
const userInitial = computed(() => {
  return authStore.user?.email?.charAt(0).toUpperCase() || 'U'
})

const customProjects = computed(() => projectsStore.customProjects)

const inboxCount = computed(() => {
  return projectsStore.inboxProject?.uncompletedTaskCount || 0
})

const todayCount = computed(() => {
  return tasksStore.todayTasks.length
})

const upcomingCount = computed(() => {
  return tasksStore.upcomingTasks.length
})

// 方法
const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

const handleCreateProject = async () => {
  if (!newProjectName.value.trim()) {
    createProjectError.value = '项目名称不能为空'
    return
  }
  
  try {
    createProjectError.value = ''
    await projectsStore.createProject({ name: newProjectName.value.trim() })
    newProjectName.value = ''
    showCreateProject.value = false
  } catch (error) {
    createProjectError.value = '创建项目失败'
  }
}

const editProject = (project: Project) => {
  editingProject.value = project
  showEditProject.value = true
}

const handleProjectUpdated = (project: Project) => {
  // 项目已在 store 中更新
  console.log('项目已更新:', project)
}

const handleProjectDeleted = (projectId: number) => {
  // 项目已在 store 中删除
  console.log('项目已删除:', projectId)
  // 如果当前在被删除的项目页面，跳转到收件箱
  if (router.currentRoute.value.name === 'project' &&
      Number(router.currentRoute.value.params.id) === projectId) {
    router.push('/dashboard')
  }
}

// 生命周期
onMounted(async () => {
  try {
    await Promise.all([
      projectsStore.fetchProjects(),
      tasksStore.fetchTodayTasks(),
      tasksStore.fetchUpcomingTasks()
    ])
  } catch (error) {
    console.error('加载侧边栏数据失败:', error)
  }
})
</script>

<style scoped>
.nav-link {
  @apply flex items-center space-x-3 px-3 py-2 text-sm font-medium rounded-lg;
  @apply text-gray-700 dark:text-gray-300;
  @apply hover:bg-gray-100 dark:hover:bg-gray-700;
  @apply transition-colors duration-200;
}

.nav-link-active {
  @apply bg-primary-100 text-primary-700;
  @apply dark:bg-primary-900 dark:text-primary-300;
}

.task-count {
  @apply ml-auto px-2 py-0.5 text-xs font-medium rounded-full;
  @apply bg-gray-200 text-gray-700;
  @apply dark:bg-gray-700 dark:text-gray-300;
}
</style>
