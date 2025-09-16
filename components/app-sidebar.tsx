"use client"

import * as React from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  Calculator,
  Users,
  CreditCard,
  FileText,
  Settings,
  Home,
  Building2,
  ChevronDown,
  LogOut,
  DollarSign,
  BarChart3,
  CheckCircle,
  TrendingUp
} from "lucide-react"

import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarFooter,
  useSidebar
} from "@/components/ui/sidebar"
import { Button } from "@/components/ui/button"
import { createClient } from "@/lib/supabase/client"
import { useRouter } from "next/navigation"
import { usePermissions } from "@/hooks/use-permissions"

// 菜单数据
const menuItems = [
  {
    title: "仪表板",
    url: "/",
    icon: Home,
    permission: null, // 所有用户都可以访问
  },
  {
    title: "贷款计算器",
    url: "/calculator",
    icon: Calculator,
    permission: null,
  },
  {
    title: "客户管理",
    url: "/customers",
    icon: Users,
    permission: null,
  },
  {
    title: "还款管理",
    url: "/repayments",
    icon: CreditCard,
    permission: null,
  },
  {
    title: "费用管理",
    url: "/expenses",
    icon: DollarSign,
    permission: "canManageExpenses",
  },
  {
    title: "员工盈亏",
    url: "/employee-profits",
    icon: BarChart3,
    permission: "canViewTeamPerformance",
  },
  {
    title: "审批工作流",
    url: "/approvals",
    icon: CheckCircle,
    permission: "canApproveRecords",
  },
  {
    title: "高级报表",
    url: "/advanced-reports",
    icon: TrendingUp,
    permission: "canViewReports",
  },
  {
    title: "月度损失报告",
    url: "/reports",
    icon: FileText,
    permission: "canViewReports",
  },
  {
    title: "系统设置",
    url: "/settings",
    icon: Settings,
    permission: "canManageUsers",
  },
]

interface AppSidebarProps {
  isCollapsed?: boolean
}

export function AppSidebar({ isCollapsed = false }: AppSidebarProps) {
  const pathname = usePathname()
  const router = useRouter()
  const supabase = createClient()
  const permissions = usePermissions()

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push("/login")
  }

  // 根据权限过滤菜单项
  const filteredMenuItems = menuItems.filter(item => {
    if (!item.permission) return true
    return permissions[item.permission as keyof typeof permissions] === true
  })

  return (
    <div className="flex flex-col h-full bg-white dark:bg-gray-900">
      {/* 头部 */}
      <div className="border-b bg-white dark:bg-gray-900">
        <div className={`flex items-center gap-3 px-4 lg:px-6 py-4 ${isCollapsed ? 'justify-center' : ''}`}>
          <div className="w-8 h-8 rounded-lg flex items-center justify-center shadow-sm bg-primary-500">
            <Building2 className="w-4 h-4 text-white" />
          </div>
          {!isCollapsed && (
            <div className="flex flex-col min-w-0">
              <h1 className="text-sm font-semibold text-foreground truncate">贷款管理</h1>
              <p className="text-xs text-muted-foreground truncate">专业金融系统</p>
            </div>
          )}
        </div>
      </div>
      
      {/* 内容区域 */}
      <div className="flex-1 px-4 py-4 bg-white dark:bg-gray-900">
        <div className="space-y-2">
          {!isCollapsed && (
            <div className="px-2 text-xs font-medium text-muted-foreground mb-2">主要功能</div>
          )}
          <div className="space-y-1">
            {filteredMenuItems.map((item) => (
              <Link 
                key={item.title} 
                href={item.url}
                className={`flex items-center gap-3 w-full h-10 px-3 lg:px-4 rounded-lg transition-colors ${
                  isCollapsed ? 'justify-center' : ''
                } ${
                  pathname === item.url 
                    ? 'bg-primary-50 text-primary-700' 
                    : 'text-muted-foreground hover:text-foreground hover:bg-muted'
                }`}
                title={isCollapsed ? item.title : undefined}
              >
                <item.icon className="w-4 h-4 flex-shrink-0" />
                {!isCollapsed && (
                  <span className="text-sm font-medium truncate">{item.title}</span>
                )}
              </Link>
            ))}
          </div>
        </div>
      </div>
      
      {/* 底部 */}
      <div className="border-t p-4 bg-white dark:bg-gray-900">
        <Button
          variant="ghost"
          onClick={handleLogout}
          className={`w-full h-10 px-3 lg:px-4 text-muted-foreground hover:text-foreground hover:bg-muted ${
            isCollapsed ? 'justify-center' : 'justify-start'
          }`}
          title={isCollapsed ? "退出登录" : undefined}
        >
          <LogOut className="w-4 h-4 flex-shrink-0" />
          {!isCollapsed && (
            <span className="text-sm font-medium truncate ml-3">退出登录</span>
          )}
        </Button>
      </div>
    </div>
  )
}