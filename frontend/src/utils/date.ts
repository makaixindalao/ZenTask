import dayjs from 'dayjs'
import relativeTime from 'dayjs/plugin/relativeTime'
import 'dayjs/locale/zh-cn'

dayjs.extend(relativeTime)
dayjs.locale('zh-cn')

export const formatDate = (date: string | Date): string => {
  return dayjs(date).format('YYYY-MM-DD')
}

export const formatDateTime = (date: string | Date): string => {
  return dayjs(date).format('YYYY-MM-DD HH:mm')
}

export const formatRelativeTime = (date: string | Date): string => {
  return dayjs(date).fromNow()
}

export const isToday = (date: string | Date): boolean => {
  return dayjs(date).isSame(dayjs(), 'day')
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
  
  if (dueDate.isSame(today, 'day')) {
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
