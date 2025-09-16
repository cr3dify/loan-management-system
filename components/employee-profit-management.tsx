"use client"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import { usePermissions } from "@/hooks/use-permissions"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { 
  TrendingUp, 
  TrendingDown, 
  DollarSign, 
  Users, 
  Calendar,
  BarChart3,
  Download,
  RefreshCw
} from "lucide-react"
import type { EmployeeProfit, User } from "@/lib/types"

export function EmployeeProfitManagement() {
  const [profits, setProfits] = useState<EmployeeProfit[]>([])
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear())
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1)
  const [selectedEmployee, setSelectedEmployee] = useState<string>("all")
  const supabase = createClient()
  const { canViewTeamPerformance, canViewAllCustomers } = usePermissions()

  useEffect(() => {
    fetchData()
  }, [selectedYear, selectedMonth, selectedEmployee])

  const fetchData = async () => {
    setLoading(true)
    try {
      // 获取员工盈亏数据
      let query = supabase
        .from("employee_profits")
        .select(`
          *,
          employee:employee_id(name, email, role)
        `)
        .eq("period_year", selectedYear)
        .eq("period_month", selectedMonth)

      if (selectedEmployee !== "all") {
        query = query.eq("employee_id", selectedEmployee)
      }

      const { data: profitData, error: profitError } = await query.order("net_profit", { ascending: false })

      if (profitError) throw profitError

      // 获取用户列表
      if (canViewAllCustomers) {
        const { data: userData, error: userError } = await supabase
          .from("users")
          .select("*")
          .order("name")

        if (userError) throw userError
        setUsers(userData || [])
      }

      setProfits(profitData || [])
    } catch (error) {
      console.error("获取盈亏数据失败:", error)
      alert(`获取数据失败: ${error instanceof Error ? error.message : '请重试'}`)
    } finally {
      setLoading(false)
    }
  }

  const calculateTeamStats = () => {
    const totalLoans = profits.reduce((sum, p) => sum + p.total_loans, 0)
    const totalRepayments = profits.reduce((sum, p) => sum + p.total_repayments, 0)
    const totalExpenses = profits.reduce((sum, p) => sum + p.total_expenses, 0)
    const totalProfit = profits.reduce((sum, p) => sum + p.net_profit, 0)
    const avgROI = profits.length > 0 ? profits.reduce((sum, p) => sum + p.roi_percentage, 0) / profits.length : 0

    return {
      totalLoans,
      totalRepayments,
      totalExpenses,
      totalProfit,
      avgROI,
      employeeCount: profits.length
    }
  }

  const getMonthName = (month: number) => {
    const months = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
    return months[month - 1]
  }

  const getROIBadge = (roi: number) => {
    if (roi > 20) {
      return <Badge className="bg-green-100 text-green-800">优秀 ({roi.toFixed(1)}%)</Badge>
    } else if (roi > 10) {
      return <Badge className="bg-blue-100 text-blue-800">良好 ({roi.toFixed(1)}%)</Badge>
    } else if (roi > 0) {
      return <Badge className="bg-yellow-100 text-yellow-800">一般 ({roi.toFixed(1)}%)</Badge>
    } else {
      return <Badge className="bg-red-100 text-red-800">亏损 ({roi.toFixed(1)}%)</Badge>
    }
  }

  const handleRecalculate = async () => {
    if (!canViewTeamPerformance) {
      alert("您没有权限重新计算盈亏")
      return
    }

    try {
      // 为所有员工重新计算盈亏
      const { data: userData } = await supabase.from("users").select("id")
      if (!userData) return

      for (const user of userData) {
        await supabase.rpc('calculate_employee_profit', {
          p_employee_id: user.id,
          p_year: selectedYear,
          p_month: selectedMonth
        })
      }

      alert("盈亏重新计算完成")
      fetchData()
    } catch (error) {
      console.error("重新计算失败:", error)
      alert(`重新计算失败: ${error instanceof Error ? error.message : '请重试'}`)
    }
  }

  const handleExport = () => {
    // 导出功能将在后续实现
    alert("导出功能开发中...")
  }

  if (!canViewTeamPerformance) {
    return (
      <main className="container mx-auto px-4 py-8">
        <Card>
          <CardContent className="p-8">
            <div className="flex flex-col items-center justify-center text-center">
              <BarChart3 className="w-16 h-16 text-muted-foreground mb-4" />
              <h2 className="text-2xl font-bold text-foreground mb-2">访问受限</h2>
              <p className="text-muted-foreground">
                您没有权限访问员工盈亏管理页面
              </p>
            </div>
          </CardContent>
        </Card>
      </main>
    )
  }

  const teamStats = calculateTeamStats()

  return (
    <main className="container mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">员工盈亏管理</h1>
          <p className="text-muted-foreground">查看员工业绩和盈亏情况</p>
        </div>
        <div className="flex gap-2">
          <Button onClick={handleRecalculate} variant="outline">
            <RefreshCw className="w-4 h-4 mr-2" />
            重新计算
          </Button>
          <Button onClick={handleExport}>
            <Download className="w-4 h-4 mr-2" />
            导出报表
          </Button>
        </div>
      </div>

      {/* 筛选器 */}
      <Card className="mb-6">
        <CardContent className="p-4">
          <div className="flex flex-wrap gap-4 items-center">
            <div>
              <label className="text-sm font-medium text-muted-foreground">年份</label>
              <select
                value={selectedYear}
                onChange={(e) => setSelectedYear(Number.parseInt(e.target.value))}
                className="ml-2 px-3 py-1 border border-border rounded-md bg-background"
              >
                {Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - i).map(year => (
                  <option key={year} value={year}>{year}年</option>
                ))}
              </select>
            </div>
            
            <div>
              <label className="text-sm font-medium text-muted-foreground">月份</label>
              <select
                value={selectedMonth}
                onChange={(e) => setSelectedMonth(Number.parseInt(e.target.value))}
                className="ml-2 px-3 py-1 border border-border rounded-md bg-background"
              >
                {Array.from({ length: 12 }, (_, i) => i + 1).map(month => (
                  <option key={month} value={month}>{getMonthName(month)}</option>
                ))}
              </select>
            </div>

            {canViewAllCustomers && (
              <div>
                <label className="text-sm font-medium text-muted-foreground">员工</label>
                <select
                  value={selectedEmployee}
                  onChange={(e) => setSelectedEmployee(e.target.value)}
                  className="ml-2 px-3 py-1 border border-border rounded-md bg-background"
                >
                  <option value="all">所有员工</option>
                  {users.map(user => (
                    <option key={user.id} value={user.id}>{user.name}</option>
                  ))}
                </select>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* 团队统计 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 mb-6">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">放款总额</p>
                <p className="text-2xl font-bold">RM {teamStats.totalLoans.toLocaleString()}</p>
              </div>
              <DollarSign className="w-8 h-8 text-blue-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">回款总额</p>
                <p className="text-2xl font-bold">RM {teamStats.totalRepayments.toLocaleString()}</p>
              </div>
              <TrendingUp className="w-8 h-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">总费用</p>
                <p className="text-2xl font-bold">RM {teamStats.totalExpenses.toLocaleString()}</p>
              </div>
              <TrendingDown className="w-8 h-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">净利润</p>
                <p className={`text-2xl font-bold ${teamStats.totalProfit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                  RM {teamStats.totalProfit.toLocaleString()}
                </p>
              </div>
              <BarChart3 className="w-8 h-8 text-purple-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">平均ROI</p>
                <p className="text-2xl font-bold">{teamStats.avgROI.toFixed(1)}%</p>
              </div>
              <Users className="w-8 h-8 text-indigo-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 员工盈亏列表 */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <BarChart3 className="w-5 h-5" />
            {selectedYear}年{getMonthName(selectedMonth)}员工盈亏详情
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center p-8">
              <div className="text-muted-foreground">加载中...</div>
            </div>
          ) : profits.length === 0 ? (
            <div className="text-center py-8">
              <BarChart3 className="w-12 h-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground">暂无盈亏数据</p>
            </div>
          ) : (
            <div className="space-y-4">
              {profits.map((profit) => (
                <div
                  key={profit.id}
                  className="border border-border rounded-lg p-4 hover:bg-muted/50 transition-colors"
                >
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <div>
                        <div className="font-medium">{profit.employee?.name}</div>
                        <div className="text-sm text-muted-foreground">
                          {profit.employee?.role} • {profit.employee?.email}
                        </div>
                      </div>
                      {getROIBadge(profit.roi_percentage)}
                    </div>
                    <div className="text-right">
                      <div className={`text-lg font-bold ${profit.net_profit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                        RM {profit.net_profit.toLocaleString()}
                      </div>
                      <div className="text-sm text-muted-foreground">净利润</div>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div>
                      <div className="text-muted-foreground">放款</div>
                      <div className="font-medium">RM {profit.total_loans.toLocaleString()}</div>
                    </div>
                    <div>
                      <div className="text-muted-foreground">回款</div>
                      <div className="font-medium">RM {profit.total_repayments.toLocaleString()}</div>
                    </div>
                    <div>
                      <div className="text-muted-foreground">费用</div>
                      <div className="font-medium">RM {profit.total_expenses.toLocaleString()}</div>
                    </div>
                    <div>
                      <div className="text-muted-foreground">ROI</div>
                      <div className="font-medium">{profit.roi_percentage.toFixed(1)}%</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </main>
  )
}
