"use client"

import * as React from "react"
import { Moon, Sun, Monitor, Palette, Sparkles } from "lucide-react"
import { useTheme } from "next-themes"

import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
  DropdownMenuLabel,
} from "@/components/ui/dropdown-menu"

const themes = [
  { name: "light", label: "浅色模式", icon: Sun, description: "Materio 经典浅色主题" },
  { name: "dark", label: "深色模式", icon: Moon, description: "Materio 深色主题，护眼舒适" },
  { name: "system", label: "跟随系统", icon: Monitor, description: "自动切换浅色/深色" },
]

export function ThemeToggle() {
  const { setTheme, theme } = useTheme()

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" size="icon">
          <Sun className="h-[1.2rem] w-[1.2rem] rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
          <Moon className="absolute h-[1.2rem] w-[1.2rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          <span className="sr-only">切换主题</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuLabel className="text-sm font-medium">选择主题风格</DropdownMenuLabel>
        <DropdownMenuSeparator />
        {themes.map((themeOption) => {
          const Icon = themeOption.icon
          const isSelected = theme === themeOption.name
          return (
            <DropdownMenuItem 
              key={themeOption.name}
              onClick={() => setTheme(themeOption.name)}
              className={`flex flex-col items-start p-3 cursor-pointer transition-colors ${
                isSelected ? 'bg-primary/10 text-primary' : 'hover:bg-muted'
              }`}
            >
              <div className="flex items-center w-full">
                <Icon className="mr-2 h-4 w-4" />
                <div className="flex-1">
                  <div className="flex items-center justify-between">
                    <span className="font-medium">{themeOption.label}</span>
                    {isSelected && (
                      <span className="text-xs text-primary font-bold">✓</span>
                    )}
                  </div>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    {themeOption.description}
                  </p>
                </div>
              </div>
            </DropdownMenuItem>
          )
        })}
        <DropdownMenuSeparator />
        <div className="px-3 py-2 text-xs text-muted-foreground border-t">
          ✨ 所有主题已优化字体清晰度
        </div>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
