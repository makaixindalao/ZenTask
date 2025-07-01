import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'
import 'dayjs/locale/zh-cn'

dayjs.extend(relativeTime)
dayjs.locale('zh-cn')

export const formatDate = (date: string | Date): string => {
  return dayjs(date).format('YYYY-MM-DD')
}

// 格式化本地日期，避免时区偏移问题
export const formatLocalDate = (date: Date): string => {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

// 获取今天的本地日期字符串
export const getTodayString = (): string => {
  return formatLocalDate(new Date())
}

export const formatDateTime = (date: string | Date): string => {
  return dayjs(date).format('YYYY-MM-DD HH:mm')
}

export const formatRelativeTime = (date: string | Date): string => {
  return dayjs(date).fromNow()
}

export const isToday = (date: string | Date): boolean => {
  // 使用本地日期字符串进行比较，避免时区问题
  const dateStr = typeof date === 'string' ? date : formatLocalDate(date)
  const todayStr = getTodayString()
  return dateStr === todayStr
}

export const isTomorrow = (date: string | Date): boolean => {
  return dayjs(date).isSame(dayjs().add(1, 'day'), 'day')
}

export const isOverdue = (date: string | Date): boolean => {
  return dayjs(date).isBefore(dayjs(), 'day')
}

export const getDaysUntilDue = (date: string | Date): number => {
  return dayjs(date).diff(dayjs(), 'day')
}

export const formatDueDate = (date: string | Date): string => {
  const dueDate = dayjs(date)
  const today = dayjs()

  // 使用改进的isToday函数进行判断
  if (isToday(date)) {
    return '今天'
  } else if (dueDate.isSame(today.add(1, 'day'), 'day')) {
    return '明天'
  } else if (dueDate.isBefore(today, 'day')) {
    return `逾期 ${Math.abs(dueDate.diff(today, 'day'))} 天`
  } else if (dueDate.diff(today, 'day') <= 7) {
    return `${dueDate.diff(today, 'day')} 天后`
  } else {
    return dueDate.format('MM-DD')
  }
}
