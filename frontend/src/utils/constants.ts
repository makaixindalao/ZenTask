// 任务优先级配置
export const PRIORITY_CONFIG = {
  low: {
    label: '低',
    color: 'text-gray-500',
    bgColor: 'bg-gray-100',
    borderColor: 'border-gray-300'
  },
  medium: {
    label: '中',
    color: 'text-blue-600',
    bgColor: 'bg-blue-100',
    borderColor: 'border-blue-300'
  },
  high: {
    label: '高',
    color: 'text-red-600',
    bgColor: 'bg-red-100',
    borderColor: 'border-red-300'
  }
}

// 任务状态配置
export const STATUS_CONFIG = {
  pending: {
    label: '待完成',
    color: 'text-gray-600',
    bgColor: 'bg-gray-100'
  },
  completed: {
    label: '已完成',
    color: 'text-green-600',
    bgColor: 'bg-green-100'
  }
}

// 视图类型
export const VIEW_TYPES = {
  INBOX: 'inbox',
  TODAY: 'today',
  UPCOMING: 'upcoming',
  PROJECT: 'project'
} as const

// 排序选项
export const SORT_OPTIONS = [
  { value: 'sortOrder', label: '自定义排序' },
  { value: 'createdAt', label: '创建时间' },
  { value: 'dueDate', label: '截止日期' },
  { value: 'priority', label: '优先级' }
]

// 筛选选项
export const FILTER_OPTIONS = {
  status: [
    { value: 'all', label: '全部' },
    { value: 'pending', label: '未完成' },
    { value: 'completed', label: '已完成' }
  ],
  priority: [
    { value: 'all', label: '全部优先级' },
    { value: 'high', label: '高优先级' },
    { value: 'medium', label: '中优先级' },
    { value: 'low', label: '低优先级' }
  ]
}

// 键盘快捷键
export const KEYBOARD_SHORTCUTS = {
  NEW_TASK: 'n',
  NEW_PROJECT: 'p',
  SEARCH: '/',
  TOGGLE_THEME: 't'
}
