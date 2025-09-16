"use client"

import { useState, useEffect, useCallback } from 'react'

export function useSidebarToggle() {
  // 从本地存储读取初始状态，默认为打开
  const [isOpen, setIsOpen] = useState(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('sidebar-open')
      return saved !== 'false'
    }
    return true
  })

  // 切换侧边栏状态
  const toggle = useCallback(() => {
    setIsOpen(prev => {
      const newState = !prev
      // 保存到本地存储
      if (typeof window !== 'undefined') {
        localStorage.setItem('sidebar-open', newState.toString())
      }
      return newState
    })
  }, [])

  // 键盘快捷键支持 (Ctrl/Cmd + B)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'b') {
        e.preventDefault()
        toggle()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [toggle])

  return {
    isOpen,
    toggle,
    setIsOpen
  }
}
