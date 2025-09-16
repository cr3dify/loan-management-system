"use client"

import { useState, useEffect, useCallback } from "react"
import { createClient } from "@/lib/supabase/client"
import { usePermissions } from "@/hooks/use-permissions"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { 
  Download, 
  FileText, 
  TrendingUp, 
  TrendingDown, 
  DollarSign,
  Calendar,
  BarChart3,
  PieChart,
  Users,
  AlertTriangle
} from "lucide-react"
import { exportToPDF, exportToExcel, exportCustomerData, exportRepaymentData, exportEmployeeProfitData } from "@/lib/export-utils"

export function AdvancedFinancialReports() {
  const [loading, setLoading] = useState(true)
  const [reportData, setReportData] = useState<any>(null)
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear())
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth() + 1)
  const [reportType, setReportType] = useState<'monthly' | 'yearly' | 'employee'>('monthly')
  const supabase = createClient()
  const { canViewReports } = usePermissions()

  const fetchReportData = useCallback(async () => {
    setLoading(true)
    try {
      // 获取客户数据
      const { data: customers, error: customersError } = await supabase
        .from("customers")
        .select("*")

      if (customersError) throw customersError

      // 获取还款数据
      const { data: repayments, error: repaymentsError } = await supabase
        .from("repayments")
        .select("*")

      if (repaymentsError) throw repaymentsError

      // 获取费用数据
      const { data: expenses, error: expensesError } = await supabase
        .from("expenses")
        .select(`
          *,
          expense_type:expense_type_id(name),
          employee:employee_id(name)
        `)
        .eq("approval_status", "approved")

      if (expensesError) throw expensesError

      // 计算报表数据
      const data = calculateReportData(customers, repayments, expenses)
      setReportData(data)
    } catch (error) {
      console.error("获取报表数据失败:", error)
      alert(`获取数据失败: ${error instanceof Error ? error.message : '请重试'}`)
    } finally {
      setLoading(false)
    }
  }, [selectedYear, selectedMonth, reportType, supabase])

  useEffect(() => {
    fetchReportData()
  }, [fetchReportData])

  const calculateReportData = (customers: any[], repayments: any[], expenses: any[]) => {
    const currentDate = new Date()
    const year = selectedYear
    const month = selectedMonth

    // 过滤当月数据
    const monthlyCustomers = customers.filter(c => {
      const createdDate = new Date(c.created_at)
      return createdDate.getFullYear() === year && createdDate.getMonth() + 1 === month
    })

    const monthlyRepayments = repayments.filter(r => {
      const paymentDate = new Date(r.payment_date)
      return paymentDate.getFullYear() === year && paymentDate.getMonth() + 1 === month
    })

    const monthlyExpenses = expenses.filter(e => {
      const expenseDate = new Date(e.expense_date)
      return expenseDate.getFullYear() === year && expenseDate.getMonth() + 1 === month
    })

    // 计算基础指标
    const totalLoans = monthlyCustomers.reduce((sum, c) => sum + (c.loan_amount || 0), 0)
    const totalRepayments = monthlyRepayments.reduce((sum, r) => sum + (r.amount || 0), 0)
    const totalExpenses = monthlyExpenses.reduce((sum, e) => sum + (e.amount || 0), 0)
    const netProfit = totalRepayments - totalExpenses

    // 计算ROI (利息÷天×30)
    const totalInterest = monthlyRepayments.reduce((sum, r) => sum + (r.interest_amount || 0), 0)
    const daysInMonth = new Date(year, month, 0).getDate()
    const monthlyROI = totalInterest / daysInMonth * 30

    // 计算坏账
    const badDebtCustomers = customers.filter(c => c.status === 'bad_debt')
    const badDebtAmount = badDebtCustomers.reduce((sum, c) => sum + (c.loss_amount || 0), 0)

    // 计算谈账
    const negotiatingCustomers = customers.filter(c => c.status === 'negotiating')
    const negotiatingAmount = negotiatingCustomers.reduce((sum, c) => sum + (c.loan_amount || 0), 0)

    // 按员工统计
    const employeeStats = calculateEmployeeStats(customers, repayments, expenses, year, month)

    return {
      period: { year, month },
      summary: {
        totalLoans,
        totalRepayments,
        totalExpenses,
        netProfit,
        monthlyROI,
        badDebtAmount,
        badDebtCount: badDebtCustomers.length,
        negotiatingAmount,
        negotiatingCount: negotiatingCustomers.length
      },
      employeeStats,
      trends: calculateTrends(customers, repayments, expenses, year, month)
    }
  }

  const calculateEmployeeStats = (customers: any[], repayments: any[], expenses: any[], year: number, month: number) => {
    const employeeMap = new Map()

    // 统计每个员工的数据
    customers.forEach(customer => {
      if (!customer.created_by) return
      
      if (!employeeMap.has(customer.created_by)) {
        employeeMap.set(customer.created_by, {
          employeeId: customer.created_by,
          employeeName: customer.name, // 这里应该从用户表获取，简化处理
          totalLoans: 0,
          totalRepayments: 0,
          totalExpenses: 0,
          customerCount: 0
        })
      }

      const stats = employeeMap.get(customer.created_by)
      stats.totalLoans += customer.loan_amount || 0
      stats.customerCount += 1
    })

    // 计算还款和费用
    repayments.forEach(repayment => {
      const customer = customers.find(c => c.id === repayment.customer_id)
      if (customer && customer.created_by) {
        const stats = employeeMap.get(customer.created_by)
        if (stats) {
          stats.totalRepayments += repayment.amount || 0
        }
      }
    })

    expenses.forEach(expense => {
      const stats = employeeMap.get(expense.employee_id)
      if (stats) {
        stats.totalExpenses += expense.amount || 0
      }
    })

    // 计算ROI
    Array.from(employeeMap.values()).forEach(stats => {
      stats.netProfit = stats.totalRepayments - stats.totalExpenses
      stats.roi = stats.totalLoans > 0 ? (stats.netProfit / stats.totalLoans) * 100 : 0
    })

    return Array.from(employeeMap.values()).sort((a, b) => b.roi - a.roi)
  }

  const calculateTrends = (customers: any[], repayments: any[], expenses: any[], year: number, month: number) => {
    // 计算前一个月的数据用于对比
    const prevMonth = month === 1 ? 12 : month - 1
    const prevYear = month === 1 ? year - 1 : year

    const prevMonthRepayments = repayments.filter(r => {
      const paymentDate = new Date(r.payment_date)
      return paymentDate.getFullYear() === prevYear && paymentDate.getMonth() + 1 === prevMonth
    })

    const prevMonthExpenses = expenses.filter(e => {
      const expenseDate = new Date(e.expense_date)
      return expenseDate.getFullYear() === prevYear && expenseDate.getMonth() + 1 === prevMonth
    })

    const prevMonthTotal = prevMonthRepayments.reduce((sum, r) => sum + (r.amount || 0), 0)
    const currentMonthTotal = repayments.filter(r => {
      const paymentDate = new Date(r.payment_date)
      return paymentDate.getFullYear() === year && paymentDate.getMonth() + 1 === month
    }).reduce((sum, r) => sum + (r.amount || 0), 0)

    const repaymentGrowth = prevMonthTotal > 0 ? ((currentMonthTotal - prevMonthTotal) / prevMonthTotal) * 100 : 0

    return {
      repaymentGrowth,
      isGrowthPositive: repaymentGrowth > 0
    }
  }

  const getMonthName = (month: number) => {
    const months = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
    return months[month - 1]
  }

  const handleExportPDF = async () => {
    try {
      if (!reportData) {
        alert("暂无数据可导出")
        return
      }

      // 根据报表类型选择导出数据
      let exportData
      if (reportType === 'employee') {
        exportData = exportEmployeeProfitData(reportData.employeeStats)
      } else {
        // 导出客户和还款数据
        const customerData = exportCustomerData(reportData.customers || [])
        const repaymentData = exportRepaymentData(reportData.repayments || [])
        
        // 合并数据
        exportData = {
          title: `${selectedYear}年${getMonthName(selectedMonth)}财务报表`,
          data: [...(reportData.customers || []), ...(reportData.repayments || [])],
          columns: [
            { key: 'type', label: '类型', type: 'string' as const },
            { key: 'name', label: '名称', type: 'string' as const },
            { key: 'amount', label: '金额', type: 'currency' as const },
            { key: 'date', label: '日期', type: 'date' as const },
          ],
          summary: {
            totalAmount: reportData.summary.totalRepayments,
            totalCount: (reportData.customers || []).length + (reportData.repayments || []).length,
            averageROI: reportData.summary.monthlyROI,
            period: `${selectedYear}年${getMonthName(selectedMonth)}`
          }
        }
      }

      await exportToPDF(exportData)
    } catch (error) {
      console.error("PDF导出失败:", error)
      alert(`PDF导出失败: ${error instanceof Error ? error.message : '请重试'}`)
    }
  }

  const handleExportExcel = async () => {
    try {
      if (!reportData) {
        alert("暂无数据可导出")
        return
      }

      // 根据报表类型选择导出数据
      let exportData
      if (reportType === 'employee') {
        exportData = exportEmployeeProfitData(reportData.employeeStats)
      } else {
        // 导出客户和还款数据
        const customerData = exportCustomerData(reportData.customers || [])
        const repaymentData = exportRepaymentData(reportData.repayments || [])
        
        // 合并数据
        exportData = {
          title: `${selectedYear}年${getMonthName(selectedMonth)}财务报表`,
          data: [...(reportData.customers || []), ...(reportData.repayments || [])],
          columns: [
            { key: 'type', label: '类型', type: 'string' as const },
            { key: 'name', label: '名称', type: 'string' as const },
            { key: 'amount', label: '金额', type: 'currency' as const },
            { key: 'date', label: '日期', type: 'date' as const },
          ],
          summary: {
            totalAmount: reportData.summary.totalRepayments,
            totalCount: (reportData.customers || []).length + (reportData.repayments || []).length,
            averageROI: reportData.summary.monthlyROI,
            period: `${selectedYear}年${getMonthName(selectedMonth)}`
          }
        }
      }

      await exportToExcel(exportData)
    } catch (error) {
      console.error("Excel导出失败:", error)
      alert(`Excel导出失败: ${error instanceof Error ? error.message : '请重试'}`)
    }
  }

  if (!canViewReports) {
    return (
      <main className="container mx-auto px-4 py-8">
        <Card>
          <CardContent className="p-8">
            <div className="flex flex-col items-center justify-center text-center">
              <BarChart3 className="w-16 h-16 text-muted-foreground mb-4" />
              <h2 className="text-2xl font-bold text-foreground mb-2">访问受限</h2>
              <p className="text-muted-foreground">
                您没有权限访问财务报表页面
              </p>
            </div>
          </CardContent>
        </Card>
      </main>
    )
  }

  if (loading) {
    return (
      <main className="container mx-auto px-4 py-8">
        <div className="flex items-center justify-center h-64">
          <div className="text-muted-foreground">加载中...</div>
        </div>
      </main>
    )
  }

  return (
    <main className="container mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">高级财务报表</h1>
          <p className="text-muted-foreground">详细的财务分析和统计报告</p>
        </div>
        <div className="flex gap-2">
          <Button onClick={handleExportPDF} variant="outline">
            <Download className="w-4 h-4 mr-2" />
            导出PDF
          </Button>
          <Button onClick={handleExportExcel}>
            <Download className="w-4 h-4 mr-2" />
            导出Excel
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

            <div>
              <label className="text-sm font-medium text-muted-foreground">报表类型</label>
              <select
                value={reportType}
                onChange={(e) => setReportType(e.target.value as any)}
                className="ml-2 px-3 py-1 border border-border rounded-md bg-background"
              >
                <option value="monthly">月度报表</option>
                <option value="yearly">年度报表</option>
                <option value="employee">员工报表</option>
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 核心指标 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">放款总额</p>
                <p className="text-2xl font-bold">RM {reportData?.summary.totalLoans.toLocaleString()}</p>
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
                <p className="text-2xl font-bold">RM {reportData?.summary.totalRepayments.toLocaleString()}</p>
                {reportData?.trends.isGrowthPositive ? (
                  <div className="flex items-center text-green-600 text-sm">
                    <TrendingUp className="w-3 h-3 mr-1" />
                    +{reportData.trends.repaymentGrowth.toFixed(1)}%
                  </div>
                ) : (
                  <div className="flex items-center text-red-600 text-sm">
                    <TrendingDown className="w-3 h-3 mr-1" />
                    {reportData?.trends.repaymentGrowth.toFixed(1)}%
                  </div>
                )}
              </div>
              <TrendingUp className="w-8 h-8 text-green-500" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">净利润</p>
                <p className={`text-2xl font-bold ${reportData?.summary.netProfit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                  RM {reportData?.summary.netProfit.toLocaleString()}
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
                <p className="text-sm text-muted-foreground">月ROI</p>
                <p className="text-2xl font-bold">{reportData?.summary.monthlyROI.toFixed(1)}%</p>
                <p className="text-xs text-muted-foreground">利息÷天×30</p>
              </div>
              <PieChart className="w-8 h-8 text-orange-500" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 风险指标 */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-red-500" />
              坏账情况
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-muted-foreground">坏账总额</span>
                <span className="font-bold text-red-600">RM {reportData?.summary.badDebtAmount.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">坏账客户数</span>
                <span className="font-bold">{reportData?.summary.badDebtCount}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Users className="w-5 h-5 text-yellow-500" />
              谈账情况
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-muted-foreground">谈账总额</span>
                <span className="font-bold text-yellow-600">RM {reportData?.summary.negotiatingAmount.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">谈账客户数</span>
                <span className="font-bold">{reportData?.summary.negotiatingCount}</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 员工业绩排行 */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="w-5 h-5" />
            员工业绩排行
          </CardTitle>
        </CardHeader>
        <CardContent>
          {reportData?.employeeStats.length === 0 ? (
            <div className="text-center py-8">
              <Users className="w-12 h-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground">暂无员工数据</p>
            </div>
          ) : (
            <div className="space-y-4">
              {reportData?.employeeStats.slice(0, 10).map((employee: any, index: number) => (
                <div
                  key={employee.employeeId}
                  className="flex items-center justify-between p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors"
                >
                  <div className="flex items-center gap-4">
                    <div className="w-8 h-8 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-sm font-bold">
                      {index + 1}
                    </div>
                    <div>
                      <div className="font-medium">{employee.employeeName}</div>
                      <div className="text-sm text-muted-foreground">
                        {employee.customerCount} 个客户
                      </div>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-6">
                    <div className="text-right">
                      <div className="text-sm text-muted-foreground">净利润</div>
                      <div className={`font-bold ${employee.netProfit >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                        RM {employee.netProfit.toLocaleString()}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm text-muted-foreground">ROI</div>
                      <div className="font-bold">{employee.roi.toFixed(1)}%</div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm text-muted-foreground">放款</div>
                      <div className="font-bold">RM {employee.totalLoans.toLocaleString()}</div>
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
