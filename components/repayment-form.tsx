"use client"

import type React from "react"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import type { Customer } from "@/lib/types"
import { LoanCalculator } from "@/lib/loan-calculator"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { X, Calculator, AlertTriangle } from "lucide-react"

interface RepaymentFormProps {
  customer?: Customer | null
  onClose: () => void
}

export function RepaymentForm({ customer: initialCustomer, onClose }: RepaymentFormProps) {
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(initialCustomer || null)
  const [customers, setCustomers] = useState<Customer[]>([])
  const [formData, setFormData] = useState({
    amount: "",
    repayment_type: "partial_principal" as "interest_only" | "partial_principal" | "full_settlement",
    payment_date: new Date().toISOString().split("T")[0],
    notes: "",
    loss_amount: "",
  })

  const [allocation, setAllocation] = useState({
    penaltyPayment: 0,
    interestPayment: 0,
    principalPayment: 0,
    remainingAmount: 0,
  })

  const [overdueInfo, setOverdueInfo] = useState({
    overdueDays: 0,
    penaltyAmount: 0,
    currentInterest: 0,
  })

  const [loading, setLoading] = useState(false)
  const supabase = createClient()

  useEffect(() => {
    if (!initialCustomer) {
      fetchCustomers()
    }
  }, [initialCustomer])

  useEffect(() => {
    if (selectedCustomer) {
      calculateOverdueInfo()
    }
  }, [selectedCustomer])

  useEffect(() => {
    if (selectedCustomer && formData.amount) {
      calculateAllocation()
    }
  }, [selectedCustomer, formData.amount, overdueInfo])

  const fetchCustomers = async () => {
    try {
      const { data, error } = await supabase.from("customers").select("*").neq("status", "cleared").order("full_name")

      if (error) throw error
      setCustomers(data || [])
    } catch (error) {
      console.error("获取客户列表失败:", error)
    }
  }

  const calculateOverdueInfo = async () => {
    if (!selectedCustomer) return

    // 这里应该根据实际的贷款记录和还款记录计算逾期信息
    // 简化处理，假设有逾期情况
    const overdueDays = selectedCustomer.status === "overdue" ? 7 : 0
    const penaltyRate = 5 // 5% 每天
    const penaltyAmount =
      overdueDays > 0
        ? LoanCalculator.calculatePenalty({
            overdueDays,
            overdueAmount: selectedCustomer.loan_amount,
            penaltyRate,
          })
        : 0

    // 计算当期应还利息（简化处理）
    const currentInterest =
      ((selectedCustomer.loan_amount || 0) * ((selectedCustomer.interest_rate || 0) / 100)) /
      (selectedCustomer.number_of_periods || 1)

    setOverdueInfo({
      overdueDays,
      penaltyAmount,
      currentInterest,
    })
  }

  const calculateAllocation = () => {
    if (!selectedCustomer || !formData.amount) return

    const paymentAmount = Number.parseFloat(formData.amount) || 0
    const remainingPrincipal = selectedCustomer.loan_amount // 简化处理

    const result = LoanCalculator.calculateRepaymentAllocation({
      paymentAmount,
      currentInterest: overdueInfo.currentInterest,
      currentPenalty: overdueInfo.penaltyAmount,
      remainingPrincipal,
    })

    setAllocation(result)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedCustomer) return

    setLoading(true)

    try {
      // 简化版：只插入最基本的字段
      const repaymentData = {
        customer_id: selectedCustomer.id,
        loan_id: selectedCustomer.id,
        amount: Number.parseFloat(formData.amount),
        principal_amount: allocation.principalPayment || 0,
        interest_amount: allocation.interestPayment || 0,
        penalty_amount: allocation.penaltyPayment || 0,
        excess_amount: allocation.remainingAmount || 0,
        repayment_type: formData.repayment_type,
        payment_date: formData.payment_date,
        due_date: formData.payment_date,
        notes: formData.notes || null
      }

      console.log('🔍 准备插入的数据:', repaymentData)
      
      const { data, error } = await supabase
        .from('repayments')
        .insert(repaymentData)
        .select()
        .single()

      if (error) {
        console.error('🚨 数据库插入失败:', error)
        throw error
      }

      console.log('✅ 还款记录添加成功:', data)

      // 处理亏损金额（如果有）
      if (formData.loss_amount && Number.parseFloat(formData.loss_amount) > 0) {
        await supabase
          .from("customers")
          .update({ loss_amount: Number.parseFloat(formData.loss_amount) })
          .eq("id", selectedCustomer.id)
      }

      onClose()
    } catch (error) {
      console.error("保存还款记录失败:", error)
      alert("保存失败，请重试")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-2 md:p-4 z-50 overflow-y-auto">
      <Card className="w-full max-w-4xl my-4 md:my-8 max-h-[calc(100vh-2rem)] md:max-h-[calc(100vh-4rem)] overflow-hidden bg-white border border-gray-200 shadow-xl rounded-lg">
        <CardHeader className="flex flex-row items-center justify-between p-3 md:p-6 bg-white border-b border-gray-200 sticky top-0 z-10">
          <CardTitle className="text-base md:text-xl font-semibold text-gray-900 truncate pr-2">添加还款记录</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose} className="shrink-0 text-gray-600 hover:text-gray-900 hover:bg-gray-100 min-w-[2rem] h-8">
            <X className="w-4 h-4" />
          </Button>
        </CardHeader>

        <CardContent className="p-3 md:p-6 bg-white overflow-y-auto flex-1">
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* 客户选择 */}
            {!initialCustomer && (
              <div>
                <Label htmlFor="customer" className="text-sm md:text-base text-gray-700 font-medium">选择客户 *</Label>
                <select
                  id="customer"
                  value={selectedCustomer?.id || ""}
                  onChange={(e) => {
                    const customer = customers.find((c) => c.id === e.target.value) // 修改为字符串比较
                    setSelectedCustomer(customer || null)
                  }}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md bg-white text-gray-900 focus:border-blue-500 focus:ring-blue-500"
                  required
                >
                  <option value="">请选择客户</option>
                  {customers.map((customer) => (
                    <option key={customer.id} value={customer.id}>
                      {customer.full_name} ({customer.customer_code}) - RM {(customer.loan_amount || 0).toLocaleString()}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {selectedCustomer && (
              <>
                {/* 客户信息 */}
                <div className="bg-card border border-border rounded-lg p-4">
                  <h3 className="text-lg font-medium mb-3">客户信息</h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <div className="text-sm text-muted-foreground">客户姓名</div>
                      <div className="font-medium">{selectedCustomer.full_name}</div>
                    </div>
                    <div>
                      <div className="text-sm text-muted-foreground">客户代号</div>
                      <div className="font-medium">{selectedCustomer.customer_code}</div>
                    </div>
                    <div>
                      <div className="text-sm text-muted-foreground">贷款金额</div>
                      <div className="font-medium">RM {(selectedCustomer.loan_amount || 0).toLocaleString()}</div>
                    </div>
                    <div>
                      <div className="text-sm text-muted-foreground">利息比例</div>
                      <div className="font-medium">{selectedCustomer.interest_rate || 0}%</div>
                    </div>
                  </div>

                  {overdueInfo.overdueDays > 0 && (
                    <div className="mt-4 p-3 bg-orange-50 border border-orange-200 rounded-lg">
                      <div className="flex items-center space-x-2 text-orange-800">
                        <AlertTriangle className="w-4 h-4" />
                        <span className="font-medium">逾期提醒</span>
                      </div>
                      <div className="mt-2 text-sm text-orange-700">
                        逾期天数: {overdueInfo.overdueDays} 天 | 罚金: RM {overdueInfo.penaltyAmount.toLocaleString()}
                      </div>
                    </div>
                  )}
                </div>

                {/* 还款信息 */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-4">
                    <h3 className="text-lg font-medium">还款信息</h3>

                    <div>
                      <Label htmlFor="amount" className="text-sm md:text-base text-gray-700 font-medium">还款金额 (RM) *</Label>
                      <Input
                        id="amount"
                        type="number"
                        step="0.01"
                        value={formData.amount}
                        onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                        required
                        className="mt-1 bg-white border-gray-300 text-gray-900 placeholder-gray-500 focus:border-blue-500 focus:ring-blue-500"
                      />
                    </div>

                    <div>
                      <Label htmlFor="repayment_type" className="text-sm md:text-base text-gray-700 font-medium">还款类型 *</Label>
                      <select
                        id="repayment_type"
                        value={formData.repayment_type}
                        onChange={(e) => setFormData({ ...formData, repayment_type: e.target.value as any })}
                        className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md bg-white text-gray-900 focus:border-blue-500 focus:ring-blue-500"
                        required
                      >
                        <option value="interest_only">只还利息</option>
                        <option value="partial_principal">部分还本金+利息</option>
                        <option value="full_settlement">一次性结清</option>
                      </select>
                    </div>



                    <div>
                      <Label htmlFor="payment_date" className="text-sm md:text-base text-gray-700 font-medium">还款日期 *</Label>
                      <Input
                        id="payment_date"
                        type="date"
                        value={formData.payment_date}
                        onChange={(e) => setFormData({ ...formData, payment_date: e.target.value })}
                        required
                        className="mt-1 bg-white border-gray-300 text-gray-900 placeholder-gray-500 focus:border-blue-500 focus:ring-blue-500"
                      />
                    </div>

                    <div>
                      <Label htmlFor="loss_amount" className="text-sm md:text-base text-gray-700 font-medium">
                        亏损金额 (RM)
                      </Label>
                      <Input
                        id="loss_amount"
                        type="number"
                        step="0.01"
                        inputMode="decimal"
                        value={formData.loss_amount}
                        onChange={(e) => setFormData({ ...formData, loss_amount: e.target.value })}
                        placeholder=""
                        className="mt-1 bg-white border-gray-300 text-gray-900 placeholder-gray-500 focus:border-blue-500 focus:ring-blue-500"
                      />
                    </div>

                    <div>
                      <Label htmlFor="notes" className="text-sm md:text-base text-gray-700 font-medium">备注</Label>
                      <Textarea
                        id="notes"
                        value={formData.notes}
                        onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                        placeholder="还款备注信息"
                        className="mt-1 min-h-[60px] bg-white border-gray-300 text-gray-900 placeholder-gray-500 focus:border-blue-500 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  {/* 还款分配 */}
                  <div className="space-y-4">
                    <div className="flex items-center space-x-2">
                      <Calculator className="w-5 h-5 text-primary" />
                      <h3 className="text-lg font-medium">还款分配</h3>
                    </div>

                    <div className="space-y-3">
                      {allocation.penaltyPayment > 0 && (
                        <div className="flex justify-between items-center p-3 bg-orange-50 border border-orange-200 rounded">
                          <span className="text-orange-800">罚金</span>
                          <span className="font-medium text-orange-800">
                            RM {allocation.penaltyPayment.toLocaleString()}
                          </span>
                        </div>
                      )}

                      <div className="flex justify-between items-center p-3 bg-blue-50 border border-blue-200 rounded">
                        <span className="text-blue-800">利息</span>
                        <span className="font-medium text-blue-800">
                          RM {allocation.interestPayment.toLocaleString()}
                        </span>
                      </div>

                      <div className="flex justify-between items-center p-3 bg-green-50 border border-green-200 rounded">
                        <span className="text-green-800">本金</span>
                        <span className="font-medium text-green-800">
                          RM {allocation.principalPayment.toLocaleString()}
                        </span>
                      </div>

                      {allocation.remainingAmount > 0 && (
                        <div className="flex justify-between items-center p-3 bg-gray-50 border border-gray-200 rounded">
                          <span className="text-gray-800">多余金额</span>
                          <span className="font-medium text-gray-800">
                            RM {allocation.remainingAmount.toLocaleString()}
                          </span>
                        </div>
                      )}
                    </div>

                    <div className="pt-3 border-t border-border">
                      <div className="flex justify-between items-center">
                        <span className="text-lg font-medium">总计</span>
                        <span className="text-lg font-bold text-primary">
                          RM {(Number.parseFloat(formData.amount) || 0).toLocaleString()}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* 提交按钮 */}
                <div className="flex items-center justify-end space-x-4">
                  <Button type="button" variant="outline" onClick={onClose}>
                    取消
                  </Button>
                  <Button
                    type="submit"
                    disabled={loading || !formData.amount}
                    className="bg-primary hover:bg-primary/90 text-primary-foreground"
                  >
                    {loading ? "保存中..." : "确认还款"}
                  </Button>
                </div>
              </>
            )}
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
