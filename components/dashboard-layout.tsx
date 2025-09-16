"use client"

import { AppSidebar } from "@/components/app-sidebar"
import { SidebarToggleButton } from "@/components/sidebar-toggle-button"
import { useSidebarToggle } from "@/hooks/use-sidebar-toggle"

interface DashboardLayoutProps {
  children: React.ReactNode
}

export function DashboardLayout({ children }: DashboardLayoutProps) {
  const { isOpen, toggle } = useSidebarToggle()

  return (
    <div className="flex h-screen w-full">
      {/* 侧边栏 */}
      <div 
        className={`${
          isOpen ? 'w-48 lg:w-64 xl:w-72' : 'w-16'
        } flex-shrink-0 border-r bg-white dark:bg-gray-900 transition-all duration-300 ease-in-out`}
        aria-hidden={!isOpen}
        role="navigation"
        aria-label="主导航菜单"
      >
        <AppSidebar isCollapsed={!isOpen} />
      </div>
      
      {/* 主内容区域 */}
      <div className="flex-1 flex flex-col overflow-hidden">
        <header className="flex h-16 shrink-0 items-center gap-2 border-b px-4 bg-background">
          <SidebarToggleButton 
            isOpen={isOpen} 
            onToggle={toggle}
            className="md:hidden"
          />
          <h1 className="text-lg font-semibold">贷款管理系统</h1>
        </header>
        <main className="flex-1 p-4 lg:p-6 bg-background overflow-auto">
          <div className="w-full">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}