"use client"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import { usePermissions } from "@/hooks/use-permissions"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Textarea } from "@/components/ui/textarea"
import { 
  CheckCircle, 
  XCircle, 
  Clock, 
  User as UserIcon, 
  FileText,
  DollarSign,
  Users,
  Calendar,
  MessageSquare
} from "lucide-react"
import type { ApprovalRecord, Customer, Expense, Repayment, User } from "@/lib/types"

export function ApprovalWorkflow() {
  const [pendingApprovals, setPendingApprovals] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedRecord, setSelectedRecord] = useState<any>(null)
  const [showApprovalDialog, setShowApprovalDialog] = useState(false)
  const [approvalComments, setApprovalComments] = useState("")
  const supabase = createClient()
  const { canApproveRecords } = usePermissions()

  useEffect(() => {
    fetchPendingApprovals()
  }, [])

  const fetchPendingApprovals = async () => {
    setLoading(true)
    try {
      // 获取待审批的客户
      const { data: customers, error: customersError } = await supabase
        .from("customers")
        .select("*")
        .eq("approval_status", "pending")

      if (customersError) throw customersError

      // 获取待审批的费用
      const { data: expenses, error: expensesError } = await supabase
        .from("expenses")
        .select(`
          *,
          expense_type:expense_type_id(name),
          employee:employee_id(name)
        `)
        .eq("approval_status", "pending")

      if (expensesError) throw expensesError

      // 合并数据并添加类型标识
      const pendingData = [
        ...(customers || []).map(c => ({ ...c, record_type: 'customer' })),
        ...(expenses || []).map(e => ({ ...e, record_type: 'expense' }))
      ]

      setPendingApprovals(pendingData)
    } catch (error) {
      console.error("获取待审批记录失败:", error)
      alert(`获取数据失败: ${error instanceof Error ? error.message : '请重试'}`)
    } finally {
      setLoading(false)
    }
  }

  const handleApproval = async (record: any, approved: boolean) => {
    if (!canApproveRecords) {
      alert("您没有审批权限")
      return
    }

    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error("用户未登录")

      if (record.record_type === 'customer') {
        const { error } = await supabase
          .from("customers")
          .update({
            approval_status: approved ? "approved" : "rejected",
            approved_by: user.id,
            approved_at: new Date().toISOString(),
            negotiation_terms: approved ? record.negotiation_terms : approvalComments
          })
          .eq("id", record.id)

        if (error) throw error
      } else if (record.record_type === 'expense') {
        const { error } = await supabase
          .from("expenses")
          .update({
            approval_status: approved ? "approved" : "rejected",
            approved_by: user.id,
            approved_at: new Date().toISOString(),
            rejection_reason: approved ? null : approvalComments
          })
          .eq("id", record.id)

        if (error) throw error
      }

      // 创建审批记录
      await supabase
        .from("approval_records")
        .insert([{
          record_type: record.record_type,
          record_id: record.id,
          approver_id: user.id,
          approval_status: approved ? "approved" : "rejected",
          approval_level: 1,
          comments: approvalComments
        }])

      alert(approved ? "审批通过" : "审批拒绝")
      setShowApprovalDialog(false)
      setSelectedRecord(null)
      setApprovalComments("")
      fetchPendingApprovals()
    } catch (error) {
      console.error("审批失败:", error)
      alert(`审批失败: ${error instanceof Error ? error.message : '请重试'}`)
    }
  }

  const getRecordIcon = (recordType: string) => {
    switch (recordType) {
      case 'customer':
        return <Users className="w-5 h-5 text-blue-500" />
      case 'expense':
        return <DollarSign className="w-5 h-5 text-green-500" />
      case 'repayment':
        return <FileText className="w-5 h-5 text-purple-500" />
      default:
        return <FileText className="w-5 h-5 text-gray-500" />
    }
  }

  const getRecordTitle = (record: any) => {
    switch (record.record_type) {
      case 'customer':
        return `客户申请 - ${record.name}`
      case 'expense':
        return `费用申请 - ${record.description}`
      case 'repayment':
        return `还款记录 - ${record.amount}`
      default:
        return '未知记录'
    }
  }

  const getRecordDetails = (record: any) => {
    switch (record.record_type) {
      case 'customer':
        return {
          amount: `贷款金额: RM ${(record.loan_amount || 0).toLocaleString()}`,
          date: `申请时间: ${new Date(record.created_at).toLocaleString("zh-CN")}`,
          status: record.status
        }
      case 'expense':
        return {
          amount: `费用金额: RM ${record.amount.toLocaleString()}`,
          date: `费用日期: ${new Date(record.expense_date).toLocaleDateString("zh-CN")}`,
          status: record.expense_type?.name
        }
      default:
        return {
          amount: '',
          date: '',
          status: ''
        }
    }
  }

  if (!canApproveRecords) {
    return (
      <main className="container mx-auto px-4 py-8">
        <Card>
          <CardContent className="p-8">
            <div className="flex flex-col items-center justify-center text-center">
              <CheckCircle className="w-16 h-16 text-muted-foreground mb-4" />
              <h2 className="text-2xl font-bold text-foreground mb-2">访问受限</h2>
              <p className="text-muted-foreground">
                您没有权限访问审批工作流页面
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
          <h1 className="text-3xl font-bold text-foreground mb-2">审批工作流</h1>
          <p className="text-muted-foreground">处理待审批的记录</p>
        </div>
        <Button onClick={fetchPendingApprovals} variant="outline">
          <Clock className="w-4 h-4 mr-2" />
          刷新
        </Button>
      </div>

      {/* 待审批列表 */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="w-5 h-5" />
            待审批记录 ({pendingApprovals.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex items-center justify-center p-8">
              <div className="text-muted-foreground">加载中...</div>
            </div>
          ) : pendingApprovals.length === 0 ? (
            <div className="text-center py-8">
              <CheckCircle className="w-12 h-12 text-green-500 mx-auto mb-4" />
              <p className="text-muted-foreground">暂无待审批记录</p>
            </div>
          ) : (
            <div className="space-y-4">
              {pendingApprovals.map((record) => {
                const details = getRecordDetails(record)
                return (
                  <div
                    key={`${record.record_type}-${record.id}`}
                    className="border border-border rounded-lg p-4 hover:bg-muted/50 transition-colors"
                  >
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-3">
                        {getRecordIcon(record.record_type)}
                        <div>
                          <div className="font-medium">{getRecordTitle(record)}</div>
                          <div className="text-sm text-muted-foreground">
                            {details.amount} • {details.date}
                          </div>
                        </div>
                      </div>
                      <Badge className="bg-yellow-100 text-yellow-800">
                        待审批
                      </Badge>
                    </div>

                    <div className="flex items-center justify-between">
                      <div className="text-sm text-muted-foreground">
                        状态: {details.status}
                      </div>
                      <div className="flex gap-2">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => {
                            setSelectedRecord(record)
                            setShowApprovalDialog(true)
                          }}
                          className="text-red-600 hover:text-red-700"
                        >
                          <XCircle className="w-3 h-3 mr-1" />
                          拒绝
                        </Button>
                        <Button
                          size="sm"
                          onClick={() => {
                            setSelectedRecord(record)
                            setShowApprovalDialog(true)
                          }}
                          className="bg-green-600 hover:bg-green-700"
                        >
                          <CheckCircle className="w-3 h-3 mr-1" />
                          批准
                        </Button>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* 审批对话框 */}
      {showApprovalDialog && selectedRecord && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <Card className="w-full max-w-md">
            <CardHeader>
              <CardTitle>审批确认</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div>
                  <p className="font-medium">{getRecordTitle(selectedRecord)}</p>
                  <p className="text-sm text-muted-foreground">
                    {getRecordDetails(selectedRecord).amount}
                  </p>
                </div>

                <div>
                  <label className="text-sm font-medium">审批意见</label>
                  <Textarea
                    value={approvalComments}
                    onChange={(e) => setApprovalComments(e.target.value)}
                    placeholder="请输入审批意见..."
                    className="mt-1"
                  />
                </div>

                <div className="flex gap-2 pt-4">
                  <Button
                    variant="outline"
                    onClick={() => {
                      setShowApprovalDialog(false)
                      setSelectedRecord(null)
                      setApprovalComments("")
                    }}
                    className="flex-1"
                  >
                    取消
                  </Button>
                  <Button
                    onClick={() => handleApproval(selectedRecord, false)}
                    variant="outline"
                    className="flex-1 text-red-600 hover:text-red-700"
                  >
                    <XCircle className="w-4 h-4 mr-1" />
                    拒绝
                  </Button>
                  <Button
                    onClick={() => handleApproval(selectedRecord, true)}
                    className="flex-1 bg-green-600 hover:bg-green-700"
                  >
                    <CheckCircle className="w-4 h-4 mr-1" />
                    批准
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </main>
  )
}
