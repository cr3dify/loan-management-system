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
  LogOut
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

// 菜单数据
const menuItems = [
  {
    title: "仪表板",
    url: "/",
    icon: Home,
  },
  {
    title: "贷款计算器",
    url: "/calculator",
    icon: Calculator,
  },
  {
    title: "客户管理",
    url: "/customers",
    icon: Users,
  },
  {
    title: "还款管理",
    url: "/repayments",
    icon: CreditCard,
  },
  {
    title: "报告生成",
    url: "/reports",
    icon: FileText,
  },
  {
    title: "系统设置",
    url: "/settings",
    icon: Settings,
  },
]

export function AppSidebar() {
  const pathname = usePathname()
  const router = useRouter()
  const supabase = createClient()

  const handleLogout = async () => {
    await supabase.auth.signOut()
    router.push("/login")
  }

  return (
    <Sidebar variant="inset">
      <SidebarHeader>
        <div className="flex items-center gap-3 px-4 py-3">
          <div className="w-10 h-10 rounded-xl flex items-center justify-center shadow-md" style={{background: 'linear-gradient(135deg, var(--color-primary) 0%, var(--color-primary-700) 100%)'}}>
            <Building2 className="w-5 h-5 text-white" />
          </div>
          <div className="flex flex-col">
            <h1 className="text-lg font-semibold" style={{color: 'var(--color-neutral-800)'}}>贷款管理</h1>
            <p className="text-sm" style={{color: 'var(--color-neutral-600)'}}>专业金融系统</p>
          </div>
        </div>
      </SidebarHeader>
      
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>主要功能</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {menuItems.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton 
                    asChild 
                    isActive={pathname === item.url}
                    tooltip={item.title}
                  >
                    <Link href={item.url} className="flex items-center gap-3">
                      <item.icon className="w-4 h-4" />
                      <span>{item.title}</span>
                    </Link>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
      
      <SidebarFooter>
        <SidebarMenu>
          <SidebarMenuItem>
            <Button
              variant="ghost"
              onClick={handleLogout}
              className="w-full justify-start text-neutral-600 hover:text-neutral-900 hover:bg-neutral-100"
            >
              <LogOut className="w-4 h-4 mr-3" />
              退出登录
            </Button>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  )
}