"use client"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import { usePermissions } from "@/hooks/use-permissions"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { 
  Plus, 
  Search, 
  Filter, 
  DollarSign, 
  Calendar, 
  User as UserIcon, 
  CheckCircle, 
  XCircle, 
  Clock,
  FileText,
  TrendingUp
} from "lucide-react"
import type { Expense, ExpenseType, User } from "@/lib/types"

export function ExpenseManagement() {
  const [expenses, setExpenses] = useState<Expense[]>([])
  const [expenseTypes, setExpenseTypes] = useState<ExpenseType[]>([])
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState("")
  const [statusFilter, setStatusFilter] = useState<string>("all")
  const [showForm, setShowForm] = useState(false)
  const [editingExpense, setEditingExpense] = useState<Expense | null>(null)
  const supabase = createClient()
  const { canManageExpenses, canApproveRecords, canViewAllCustomers } = usePermissions()

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    setLoading(true)
    try {
      // 获取费用记录
      const { data: expenseData, error: expenseError } = await supabase
        .from("expenses")
        .select(`
          *,
          expense_type:expense_type_id(name, description),
          employee:employee_id(name, email),
          approver:approved_by(name, email)
        `)
        .order("created_at", { ascending: false })

      if (expenseError) throw expenseError

      // 获取费用类型
      const { data: typeData, error: typeError } = await supabase
        .from("expense_types")
        .select("*")
        .eq("is_active", true)
        .order("name")

      if (typeError) throw typeError

      // 获取用户列表（用于审批）
      if (canViewAllCustomers) {
        const { data: userData, error: userError } = await supabase
          .from("users")
          .select("*")
          .order("name")

        if (userError) throw userError
        setUsers(userData || [])
      }

      setExpenses(expenseData || [])
      setExpenseTypes(typeData || [])
    } catch (error) {
      console.error("获取费用数据失败:", error)
      alert(`获取数据失败: ${error instanceof Error ? error.message : '请重试'}`)
    } finally {
      setLoading(false)
    }
  }

  const filteredExpenses = expenses.filter((expense) => {
    const matchesSearch = (
      expense.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
      expense.employee?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      expense.expense_type?.name?.toLowerCase().includes(searchTerm.toLowerCase())
    )
    
    const matchesStatus = statusFilter === "all" || expense.approval_status === statusFilter
    
    return matchesSearch && matchesStatus
  })

  const getStatusBadge = (status: string) => {
    const statusMap = {
      pending: { label: "待审批", className: "bg-yellow-100 text-yellow-800", icon: Clock },
      approved: { label: "已批准", className: "bg-green-100 text-green-800", icon: CheckCircle },
      rejected: { label: "已拒绝", className: "bg-red-100 text-red-800", icon: XCircle },
    }

    const statusInfo = statusMap[status as keyof typeof statusMap] || statusMap.pending
    const IconComponent = statusInfo.icon
    return (
      <Badge className={`${statusInfo.className} flex items-center gap-1`}>
        <IconComponent className="w-3 h-3" />
        {statusInfo.label}
      </Badge>
    )
  }

  const handleApproveExpense = async (expenseId: string, approved: boolean, reason?: string) => {
    if (!canApproveRecords) {
      alert("您没有审批权限")
      return
    }

    try {
      const { error } = await supabase
        .from("expenses")
        .update({
          approval_status: approved ? "approved" : "rejected",
          approved_by: (await supabase.auth.getUser()).data.user?.id,
          approved_at: new Date().toISOString(),
          rejection_reason: approved ? null : reason
        })
        .eq("id", expenseId)

      if (error) throw error

      alert(approved ? "费用已批准" : "费用已拒绝")
      fetchData()
    } catch (error) {
      console.error("审批失败:", error)
      alert(`审批失败: ${error instanceof Error ? error.message : '请重试'}`)
    }
  }

  if (!canManageExpenses) {
    return (
      <main className="container mx-auto px-4 py-8">
        <Card>
          <CardContent className="p-8">
            <div className="flex flex-col items-center justify-center text-center">
              <FileText className="w-16 h-16 text-muted-foreground mb-4" />
              <h2 className="text-2xl font-bold text-foreground mb-2">访问受限</h2>
              <p className="text-muted-foreground">
                您没有权限访问费用管理页面
              </p>
            </div>
          </CardContent>
        </Card>
      </main>
    )
  }

  return (
    <main className="container mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-foreground mb-2">费用管理</h1>
          <p className="text-muted-foreground">管理员工费用和审批流程</p>
        </div>
        <Button onClick={() => setShowForm(true)} className="bg-primary hover:bg-primary/90">
          <Plus className="w-4 h-4 mr-2" />
          添加费用
        </Button>
      </div>

      {/* 搜索和过滤 */}
      <div className="flex flex-col gap-4 mb-6 lg:flex-row lg:items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4" />
          <Input
            placeholder="搜索费用描述、员工或类型..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        
        <div className="relative">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="w-full lg:w-auto px-3 py-2 border border-border rounded-md bg-background"
          >
            <option value="all">所有状态</option>
            <option value="pending">待审批</option>
            <option value="approved">已批准</option>
            <option value="rejected">已拒绝</option>
          </select>
          <Filter className="absolute right-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4 pointer-events-none" />
        </div>
      </div>

      {/* 费用列表 */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <DollarSign className="w-5 h-5" />
            费用记录
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center p-8">
              <div className="text-muted-foreground">加载中...</div>
            </div>
          ) : filteredExpenses.length === 0 ? (
            <div className="text-center py-8">
              <FileText className="w-12 h-12 text-muted-foreground mx-auto mb-4" />
              <p className="text-muted-foreground">暂无费用记录</p>
            </div>
          ) : (
            <div className="space-y-4">
              {filteredExpenses.map((expense) => (
                <div
                  key={expense.id}
                  className="border border-border rounded-lg p-4 hover:bg-muted/50 transition-colors"
                >
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <div>
                        <div className="font-medium">{expense.description}</div>
                        <div className="text-sm text-muted-foreground">
                          {expense.expense_type?.name} • {expense.employee?.name}
                        </div>
                      </div>
                      {getStatusBadge(expense.approval_status)}
                    </div>
                    <div className="text-right">
                      <div className="text-lg font-bold text-primary">
                        RM {expense.amount.toLocaleString()}
                      </div>
                      <div className="flex items-center text-sm text-muted-foreground">
                        <Calendar className="w-3 h-3 mr-1" />
                        {new Date(expense.expense_date).toLocaleDateString("zh-CN")}
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center justify-between">
                    <div className="text-sm text-muted-foreground">
                      创建时间: {new Date(expense.created_at).toLocaleString("zh-CN")}
                    </div>
                    
                    {canApproveRecords && expense.approval_status === "pending" && (
                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleApproveExpense(expense.id, false, "费用不合理")}
                          className="text-red-600 hover:text-red-700"
                        >
                          <XCircle className="w-3 h-3 mr-1" />
                          拒绝
                        </Button>
                        <Button
                          size="sm"
                          onClick={() => handleApproveExpense(expense.id, true)}
                          className="bg-green-600 hover:bg-green-700"
                        >
                          <CheckCircle className="w-3 h-3 mr-1" />
                          批准
                        </Button>
                      </div>
                    )}
                  </div>

                  {expense.rejection_reason && (
                    <div className="mt-2 p-2 bg-red-50 border border-red-200 rounded text-sm text-red-700">
                      拒绝原因: {expense.rejection_reason}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* 费用表单 */}
      {showForm && (
        <ExpenseForm
          expense={editingExpense}
          expenseTypes={expenseTypes}
          onClose={() => {
            setShowForm(false)
            setEditingExpense(null)
            fetchData()
          }}
        />
      )}
    </main>
  )
}

// 费用表单组件
interface ExpenseFormProps {
  expense?: Expense | null
  expenseTypes: ExpenseType[]
  onClose: () => void
}

function ExpenseForm({ expense, expenseTypes, onClose }: ExpenseFormProps) {
  const [formData, setFormData] = useState({
    expense_type_id: "",
    amount: "",
    description: "",
    expense_date: new Date().toISOString().split("T")[0],
    receipt_url: "",
  })
  const [loading, setLoading] = useState(false)
  const supabase = createClient()

  useEffect(() => {
    if (expense) {
      setFormData({
        expense_type_id: expense.expense_type_id,
        amount: expense.amount.toString(),
        description: expense.description,
        expense_date: expense.expense_date,
        receipt_url: expense.receipt_url || "",
      })
    }
  }, [expense])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error("用户未登录")

      const expenseData = {
        employee_id: user.id,
        expense_type_id: formData.expense_type_id,
        amount: Number.parseFloat(formData.amount),
        description: formData.description,
        expense_date: formData.expense_date,
        receipt_url: formData.receipt_url || null,
      }

      if (expense) {
        const { error } = await supabase
          .from("expenses")
          .update(expenseData)
          .eq("id", expense.id)
        if (error) throw error
      } else {
        const { error } = await supabase
          .from("expenses")
          .insert([expenseData])
        if (error) throw error
      }

      alert(expense ? "费用更新成功" : "费用提交成功")
      onClose()
    } catch (error) {
      console.error("保存费用失败:", error)
      alert(`保存失败: ${error instanceof Error ? error.message : '请重试'}`)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <Card className="w-full max-w-md max-h-[90vh] overflow-y-auto">
        <CardHeader>
          <CardTitle>{expense ? "编辑费用" : "添加费用"}</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <Label htmlFor="expense_type">费用类型 *</Label>
              <select
                id="expense_type"
                value={formData.expense_type_id}
                onChange={(e) => setFormData({ ...formData, expense_type_id: e.target.value })}
                className="w-full px-3 py-2 border border-border rounded-md bg-background"
                required
              >
                <option value="">选择费用类型</option>
                {expenseTypes.map((type) => (
                  <option key={type.id} value={type.id}>
                    {type.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <Label htmlFor="amount">金额 (RM) *</Label>
              <Input
                id="amount"
                type="number"
                step="0.01"
                value={formData.amount}
                onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                required
              />
            </div>

            <div>
              <Label htmlFor="description">描述 *</Label>
              <Textarea
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                required
              />
            </div>

            <div>
              <Label htmlFor="expense_date">费用日期 *</Label>
              <Input
                id="expense_date"
                type="date"
                value={formData.expense_date}
                onChange={(e) => setFormData({ ...formData, expense_date: e.target.value })}
                required
              />
            </div>

            <div>
              <Label htmlFor="receipt_url">收据链接</Label>
              <Input
                id="receipt_url"
                type="url"
                value={formData.receipt_url}
                onChange={(e) => setFormData({ ...formData, receipt_url: e.target.value })}
                placeholder="https://..."
              />
            </div>

            <div className="flex gap-2 pt-4">
              <Button type="button" variant="outline" onClick={onClose} className="flex-1">
                取消
              </Button>
              <Button type="submit" disabled={loading} className="flex-1">
                {loading ? "保存中..." : expense ? "更新" : "提交"}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
