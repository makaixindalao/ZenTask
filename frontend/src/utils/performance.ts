// 性能监控工具

// 防抖函数
export function debounce<T extends (...args: any[]) => any>(
  func: T,
  wait: number
): (...args: Parameters<T>) => void {
  let timeout: NodeJS.Timeout | null = null
  
  return (...args: Parameters<T>) => {
    if (timeout) {
      clearTimeout(timeout)
    }
    
    timeout = setTimeout(() => {
      func(...args)
    }, wait)
  }
}

// 节流函数
export function throttle<T extends (...args: any[]) => any>(
  func: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle = false
  
  return (...args: Parameters<T>) => {
    if (!inThrottle) {
      func(...args)
      inThrottle = true
      setTimeout(() => {
        inThrottle = false
      }, limit)
    }
  }
}

// 延迟加载
export function lazyLoad<T>(
  loader: () => Promise<T>,
  delay = 0
): Promise<T> {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      loader().then(resolve).catch(reject)
    }, delay)
  })
}

// 内存使用监控
export function getMemoryUsage(): PerformanceMemory | null {
  if ('memory' in performance) {
    return (performance as any).memory
  }
  return null
}

// 性能标记
export function markPerformance(name: string): void {
  if ('mark' in performance) {
    performance.mark(name)
  }
}

// 性能测量
export function measurePerformance(name: string, startMark: string, endMark: string): number | null {
  if ('measure' in performance && 'getEntriesByName' in performance) {
    performance.measure(name, startMark, endMark)
    const entries = performance.getEntriesByName(name)
    return entries.length > 0 ? entries[0].duration : null
  }
  return null
}

// 图片懒加载
export function setupImageLazyLoading(): void {
  if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const img = entry.target as HTMLImageElement
          if (img.dataset.src) {
            img.src = img.dataset.src
            img.classList.remove('lazy')
            imageObserver.unobserve(img)
          }
        }
      })
    })

    document.querySelectorAll('img[data-src]').forEach((img) => {
      imageObserver.observe(img)
    })
  }
}

// 预加载关键资源
export function preloadResource(href: string, as: string): void {
  const link = document.createElement('link')
  link.rel = 'preload'
  link.href = href
  link.as = as
  document.head.appendChild(link)
}

// 检查网络连接质量
export function getNetworkInfo(): any {
  if ('connection' in navigator) {
    return (navigator as any).connection
  }
  return null
}

// 虚拟滚动辅助函数
export function calculateVisibleItems(
  containerHeight: number,
  itemHeight: number,
  scrollTop: number,
  buffer = 5
): { start: number; end: number } {
  const visibleCount = Math.ceil(containerHeight / itemHeight)
  const start = Math.max(0, Math.floor(scrollTop / itemHeight) - buffer)
  const end = start + visibleCount + buffer * 2
  
  return { start, end }
}

// 批量DOM更新
export function batchDOMUpdates(updates: (() => void)[]): void {
  requestAnimationFrame(() => {
    updates.forEach(update => update())
  })
}

// 检查是否支持WebP
export function supportsWebP(): Promise<boolean> {
  return new Promise((resolve) => {
    const webP = new Image()
    webP.onload = webP.onerror = () => {
      resolve(webP.height === 2)
    }
    webP.src = 'data:image/webp;base64,UklGRjoAAABXRUJQVlA4IC4AAACyAgCdASoCAAIALmk0mk0iIiIiIgBoSygABc6WWgAA/veff/0PP8bA//LwYAAA'
  })
}

// 资源加载优先级
export function setResourcePriority(element: HTMLElement, priority: 'high' | 'low'): void {
  if ('importance' in element) {
    (element as any).importance = priority
  }
}
