"use client"

import { Button } from "@/components/ui/button"
import { Menu, X } from "lucide-react"

interface SidebarToggleButtonProps {
  isOpen: boolean
  onToggle: () => void
  className?: string
}

export function SidebarToggleButton({ 
  isOpen, 
  onToggle, 
  className = "" 
}: SidebarToggleButtonProps) {
  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={onToggle}
      className={`focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 ${className}`}
      aria-label={isOpen ? "关闭侧边栏" : "打开侧边栏"}
      aria-expanded={isOpen}
    >
      {isOpen ? (
        <X className="h-4 w-4" />
      ) : (
        <Menu className="h-4 w-4" />
      )}
    </Button>
  )
}
