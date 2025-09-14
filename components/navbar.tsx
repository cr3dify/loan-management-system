"use client"

import { useState } from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Menu, X, Users, Calculator, CreditCard, Settings, Home, TrendingDown, LogOut, Building2 } from "lucide-react"
import { useAuth } from "@/components/auth-provider"

export function Navbar() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const pathname = usePathname()
  const { user, signOut } = useAuth()

  const menuItems = [
    { icon: Home, label: "首页", href: "/", description: "系统概览" },
    { icon: Users, label: "客户管理", href: "/customers", description: "客户信息与状态" },
    { icon: Calculator, label: "贷款计算", href: "/calculator", description: "利息计算器" },
    { icon: CreditCard, label: "还款管理", href: "/repayments", description: "还款记录" },
    { icon: TrendingDown, label: "亏损报告", href: "/reports", description: "财务分析" },
    { icon: Settings, label: "系统设置", href: "/settings", description: "系统配置" },
  ]

  const isActive = (href: string) => {
    if (href === "/") {
      return pathname === "/"
    }
    return pathname.startsWith(href)
  }

  const handleSignOut = async () => {
    await signOut()
    setIsMenuOpen(false)
  }

  return (
    <nav className="modern-navbar">
      <div className="modern-container">
        <div className="flex items-center justify-between h-16">
          {/* 现代化Logo */}
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-primary-500 to-primary-700 rounded-xl flex items-center justify-center shadow-md">
              <Building2 className="w-5 h-5 text-white" />
            </div>
            <div className="flex flex-col">
              <Link href="/" className="font-display font-bold text-lg text-neutral-800 hover:text-primary-600 transition-colors">
                贷款管理系统
              </Link>
              <span className="text-xs text-neutral-500 font-medium">专业金融管理平台</span>
            </div>
          </div>

          {/* 桌面端现代化菜单 */}
          <div className="hidden lg:flex items-center gap-1">
            {menuItems.map((item) => (
              <Link key={item.label} href={item.href}>
                <div className={`
                  group relative px-4 py-2 rounded-lg transition-all duration-200
                  ${
                    isActive(item.href)
                      ? "bg-primary-50 text-primary-700"
                      : "text-neutral-600 hover:text-neutral-800 hover:bg-neutral-100"
                  }
                `}>
                  <div className="flex items-center gap-2">
                    <item.icon className={`w-4 h-4 ${
                      isActive(item.href) ? "text-primary-600" : "text-neutral-500 group-hover:text-neutral-600"
                    }`} />
                    <span className="font-medium text-sm">{item.label}</span>
                  </div>
                  
                  {/* 悬停提示 */}
                  <div className="absolute top-full left-1/2 transform -translate-x-1/2 mt-2 px-3 py-1 bg-neutral-800 text-white text-xs rounded-md opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none whitespace-nowrap z-50">
                    {item.description}
                    <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 border-4 border-transparent border-b-neutral-800"></div>
                  </div>
                </div>
              </Link>
            ))}
          </div>

          {/* 用户信息和操作 */}
          <div className="flex items-center gap-4">
            {user && (
              <div className="hidden lg:flex items-center gap-3">
                <div className="flex flex-col items-end">
                  <span className="text-sm font-medium text-neutral-700">
                    {user.user_metadata?.username || "管理员"}
                  </span>
                  <span className="text-xs text-neutral-500">在线</span>
                </div>
                <div className="w-8 h-8 bg-gradient-to-br from-primary-400 to-primary-600 rounded-lg flex items-center justify-center text-white text-sm font-semibold shadow-sm">
                  {(user.user_metadata?.username || "A").charAt(0).toUpperCase()}
                </div>
                <button
                  onClick={handleSignOut}
                  className="modern-button modern-button-ghost p-2"
                  title="登出"
                >
                  <LogOut className="w-4 h-4" />
                </button>
              </div>
            )}

            {/* 移动端菜单按钮 */}
            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="lg:hidden modern-button modern-button-ghost p-2"
            >
              {isMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* 移动端现代化菜单 */}
        {isMenuOpen && (
          <div className="lg:hidden py-4 border-t border-neutral-200 animate-slide-down">
            <div className="flex flex-col gap-2">
              {menuItems.map((item) => (
                <Link key={item.label} href={item.href} onClick={() => setIsMenuOpen(false)}>
                  <div className={`
                    flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200
                    ${
                      isActive(item.href)
                        ? "bg-primary-50 text-primary-700 border-l-4 border-primary-500"
                        : "text-neutral-600 hover:text-neutral-800 hover:bg-neutral-100"
                    }
                  `}>
                    <item.icon className={`w-5 h-5 ${
                      isActive(item.href) ? "text-primary-600" : "text-neutral-500"
                    }`} />
                    <div className="flex flex-col">
                      <span className="font-medium text-sm">{item.label}</span>
                      <span className="text-xs text-neutral-500">{item.description}</span>
                    </div>
                  </div>
                </Link>
              ))}
              
              {user && (
                <>
                  <div className="border-t border-neutral-200 my-2"></div>
                  <div className="px-4 py-3 bg-neutral-50 rounded-lg">
                    <div className="flex items-center gap-3 mb-3">
                      <div className="w-10 h-10 bg-gradient-to-br from-primary-400 to-primary-600 rounded-lg flex items-center justify-center text-white font-semibold">
                        {(user.user_metadata?.username || "A").charAt(0).toUpperCase()}
                      </div>
                      <div className="flex flex-col">
                        <span className="font-medium text-neutral-700">
                          {user.user_metadata?.username || "管理员"}
                        </span>
                        <span className="text-xs text-neutral-500">在线状态</span>
                      </div>
                    </div>
                    <button
                      onClick={handleSignOut}
                      className="w-full modern-button modern-button-secondary text-left"
                    >
                      <LogOut className="w-4 h-4" />
                      <span>退出登录</span>
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        )}
      </div>
    </nav>
  )
}
