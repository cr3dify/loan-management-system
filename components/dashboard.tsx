"use client"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import { 
  Users, 
  DollarSign, 
  TrendingUp, 
  AlertTriangle, 
  Activity, 
  ArrowUpRight, 
  ArrowDownRight,
  CreditCard,
  Calendar,
  Calculator,
  Target
} from "lucide-react"
import { Badge } from "@/components/ui/badge"

interface Customer {
  id: string
  full_name: string
  customer_code: string
  loan_amount: number
  status: string
  created_at: string
}

interface Repayment {
  id: string
  customer_id: string
  amount: number
  payment_date: string
  repayment_type: string
  customer: {
    full_name: string
  } | null // 明确指定外键后返回单个对象
}

interface Stats {
  totalCustomers: number
  activeLoans: number
  totalLoanAmount: number
  pendingAmount: number
  monthlyIncome: number
  totalRepayments: number
  overdueCustomers: number
  clearedCustomers: number
}

export function Dashboard() {
  const [loading, setLoading] = useState(true)
  const [stats, setStats] = useState<Stats>({
    totalCustomers: 0,
    activeLoans: 0,
    totalLoanAmount: 0,
    pendingAmount: 0,
    monthlyIncome: 0,
    totalRepayments: 0,
    overdueCustomers: 0,
    clearedCustomers: 0
  })
  const [recentCustomers, setRecentCustomers] = useState<Customer[]>([])
  const [recentRepayments, setRecentRepayments] = useState<Repayment[]>([])

  const supabase = createClient()

  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      // 获取客户统计
      const { data: customers, error: customersError } = await supabase
        .from("customers")
        .select("*")

      if (customersError) throw customersError

      // 获取还款记录（明确指定外键关系）
      const { data: repayments, error: repaymentsError } = await supabase
        .from("repayments")
        .select(`
          id,
          customer_id,
          amount,
          principal_amount,
          interest_amount,
          penalty_amount,
          payment_date,
          repayment_type,
          notes,
          customer:customer_id(full_name)
        `)
        .order("payment_date", { ascending: false })
        .limit(5)

      if (repaymentsError) throw repaymentsError

      // 计算统计数据
      const totalCustomers = customers?.length || 0
      const activeLoans = customers?.filter(c => c.status !== "cleared").length || 0
      const totalLoanAmount = customers?.reduce((sum, c) => sum + (Number(c.loan_amount) || 0), 0) || 0
      const clearedCustomers = customers?.filter(c => c.status === "cleared").length || 0
      const overdueCustomers = customers?.filter(c => c.status === "overdue").length || 0

      // 计算本月收入
      const thisMonth = new Date()
      thisMonth.setDate(1)
      const monthlyRepayments = repayments?.filter(r => 
        new Date(r.payment_date) >= thisMonth
      ) || []
      const monthlyIncome = monthlyRepayments.reduce((sum, r) => sum + Number(r.amount), 0)

      setStats({
        totalCustomers,
        activeLoans,
        totalLoanAmount,
        pendingAmount: totalLoanAmount * 0.8, // 假设80%为待收
        monthlyIncome,
        totalRepayments: repayments?.length || 0,
        overdueCustomers,
        clearedCustomers
      })

      setRecentCustomers(customers?.slice(0, 5) || [])
      setRecentRepayments((repayments as any)?.slice(0, 5) || [])

    } catch (error) {
      console.error("获取Dashboard数据失败:", error)
    } finally {
      setLoading(false)
    }
  }

  const getStatusBadge = (status: string) => {
    const statusMap = {
      normal: { label: "正常", className: "bg-primary-50 text-primary-700 border-primary-200" },
      cleared: { label: "清完", className: "bg-success-50 text-success-700 border-success-200" },
      negotiating: { label: "谈账", className: "bg-warning-50 text-warning-700 border-warning-200" },
      bad_debt: { label: "烂账", className: "bg-error-50 text-error-700 border-error-200" },
      overdue: { label: "逾期", className: "bg-orange-50 text-orange-700 border-orange-200" },
    }

    const statusInfo = statusMap[status as keyof typeof statusMap] || statusMap.normal
    return <Badge className={`modern-badge ${statusInfo.className}`}>{statusInfo.label}</Badge>
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="flex items-center gap-3">
          <Activity className="w-5 h-5 animate-spin text-primary-500" />
          <span className="text-neutral-600">加载中...</span>
        </div>
      </div>
    )
  }

  const statCards = [
    {
      title: "总客户数",
      value: stats.totalCustomers,
      subtitle: `活跃贷款: ${stats.activeLoans}`,
      icon: Users,
      trend: "+12%",
      trendUp: true,
      color: "primary"
    },
    {
      title: "贷款总额",
      value: `RM ${stats.totalLoanAmount.toLocaleString()}`,
      subtitle: `待收: RM ${stats.pendingAmount.toLocaleString()}`,
      icon: DollarSign,
      trend: "+8.2%",
      trendUp: true,
      color: "success"
    },
    {
      title: "本月收入",
      value: `RM ${stats.monthlyIncome.toLocaleString()}`,
      subtitle: `还款记录: ${stats.totalRepayments}`,
      icon: TrendingUp,
      trend: "+15.3%",
      trendUp: true,
      color: "info"
    },
    {
      title: "风险客户",
      value: stats.overdueCustomers,
      subtitle: `已结清: ${stats.clearedCustomers}`,
      icon: AlertTriangle,
      trend: "-2.1%",
      trendUp: false,
      color: "warning"
    }
  ]

  return (
    <div className="space-y-8">
      {/* 现代化标题区域 */}
      <div className="text-center lg:text-left">
        <h1 className="font-display text-3xl lg:text-4xl font-bold text-neutral-800 mb-2">
          系统概览
        </h1>
        <p className="text-neutral-600 text-lg">贷款管理系统数据统计和最新动态</p>
      </div>

      {/* 现代化统计卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statCards.map((card, index) => (
          <div key={index} className="modern-card group hover:scale-105 transition-transform duration-300">
            <div className="modern-card-content">
              <div className="flex items-center justify-between mb-4">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                  card.color === 'primary' ? 'bg-primary-100 text-primary-600' :
                  card.color === 'success' ? 'bg-green-100 text-green-600' :
                  card.color === 'info' ? 'bg-blue-100 text-blue-600' :
                  card.color === 'warning' ? 'bg-orange-100 text-orange-600' : ''
                }`}>
                  <card.icon className="w-6 h-6" />
                </div>
                <div className={`flex items-center gap-1 px-2 py-1 rounded-lg text-xs font-medium ${
                  card.trendUp 
                    ? 'bg-green-100 text-green-700' 
                    : 'bg-red-100 text-red-700'
                }`}>
                  {card.trendUp ? (
                    <ArrowUpRight className="w-3 h-3" />
                  ) : (
                    <ArrowDownRight className="w-3 h-3" />
                  )}
                  {card.trend}
                </div>
              </div>
              
              <div>
                <h3 className="text-sm font-medium text-neutral-600 mb-1">{card.title}</h3>
                <div className="text-2xl font-bold text-neutral-800 mb-1">{card.value}</div>
                <p className="text-xs text-neutral-500">{card.subtitle}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* 现代化数据展示区域 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* 最新客户 */}
        <div className="modern-card">
          <div className="modern-card-header">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center">
                <Users className="w-4 h-4 text-primary-600" />
              </div>
              <h3 className="modern-card-title">最新客户</h3>
            </div>
          </div>
          <div className="modern-card-content">
            {recentCustomers.length === 0 ? (
              <div className="text-center py-8 text-neutral-500">
                <Users className="w-12 h-12 mx-auto mb-3 text-neutral-300" />
                <p>暂无客户数据</p>
              </div>
            ) : (
              <div className="space-y-4">
                {recentCustomers.map((customer) => (
                  <div
                    key={customer.id}
                    className="flex items-center justify-between p-4 bg-neutral-50 rounded-xl hover:bg-neutral-100 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center">
                        <span className="text-primary-600 font-semibold text-sm">
                          {(customer.full_name || 'U').charAt(0).toUpperCase()}
                        </span>
                      </div>
                      <div>
                        <div className="font-medium text-neutral-800">{customer.full_name}</div>
                        <div className="text-sm text-neutral-500">{customer.customer_code}</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-semibold text-neutral-800">
                        RM {(customer.loan_amount || 0).toLocaleString()}
                      </div>
                      {getStatusBadge(customer.status)}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* 最新还款 */}
        <div className="modern-card">
          <div className="modern-card-header">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                <CreditCard className="w-4 h-4 text-green-600" />
              </div>
              <h3 className="modern-card-title">最新还款</h3>
            </div>
          </div>
          <div className="modern-card-content">
            {recentRepayments.length === 0 ? (
              <div className="text-center py-8 text-neutral-500">
                <CreditCard className="w-12 h-12 mx-auto mb-3 text-neutral-300" />
                <p>暂无还款记录</p>
              </div>
            ) : (
              <div className="space-y-4">
                {recentRepayments.map((repayment) => (
                  <div
                    key={repayment.id}
                    className="flex items-center justify-between p-4 bg-neutral-50 rounded-xl hover:bg-neutral-100 transition-colors"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                        <Calendar className="w-4 h-4 text-green-600" />
                      </div>
                      <div>
                        <div className="font-medium text-neutral-800">
                          {(repayment.customer as any)?.[0]?.full_name || repayment.customer?.full_name || '未知客户'}
                        </div>
                        <div className="text-sm text-neutral-500">
                          {new Date(repayment.payment_date).toLocaleDateString("zh-CN")}
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-semibold text-green-600">
                        RM {repayment.amount.toLocaleString()}
                      </div>
                      <div className="text-xs text-neutral-500">
                        {repayment.repayment_type === "partial_principal"
                          ? "部分还款"
                          : repayment.repayment_type === "full_settlement"
                            ? "全额结清"
                            : "只还利息"}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* 现代化快速操作 */}
      <div className="modern-card">
        <div className="modern-card-header">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
              <Target className="w-4 h-4 text-blue-600" />
            </div>
            <h3 className="modern-card-title">快速操作</h3>
          </div>
        </div>
        <div className="modern-card-content">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <a
              href="/customers"
              className="group flex items-center gap-4 p-4 bg-neutral-50 rounded-xl hover:bg-primary-50 hover:border-primary-200 border border-transparent transition-all duration-200"
            >
              <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center group-hover:bg-primary-200 transition-colors">
                <Users className="w-6 h-6 text-primary-600" />
              </div>
              <div>
                <div className="font-semibold text-neutral-800 group-hover:text-primary-700">客户管理</div>
                <div className="text-sm text-neutral-500">添加和管理客户信息</div>
              </div>
            </a>

            <a
              href="/calculator"
              className="group flex items-center gap-4 p-4 bg-neutral-50 rounded-xl hover:bg-blue-50 hover:border-blue-200 border border-transparent transition-all duration-200"
            >
              <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center group-hover:bg-blue-200 transition-colors">
                <Calculator className="w-6 h-6 text-blue-600" />
              </div>
              <div>
                <div className="font-semibold text-neutral-800 group-hover:text-blue-700">贷款计算</div>
                <div className="text-sm text-neutral-500">计算贷款利息和还款</div>
              </div>
            </a>

            <a
              href="/repayments"
              className="group flex items-center gap-4 p-4 bg-neutral-50 rounded-xl hover:bg-green-50 hover:border-green-200 border border-transparent transition-all duration-200"
            >
              <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center group-hover:bg-green-200 transition-colors">
                <CreditCard className="w-6 h-6 text-green-600" />
              </div>
              <div>
                <div className="font-semibold text-neutral-800 group-hover:text-green-700">还款管理</div>
                <div className="text-sm text-neutral-500">记录和管理还款</div>
              </div>
            </a>
          </div>
        </div>
      </div>
    </div>
  )
}