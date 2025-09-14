"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import type { Customer } from "@/lib/types"
import { LoanCalculator, type LoanCalculationParams } from "@/lib/loan-calculator"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { X, Calculator, FileText, CheckCircle } from "lucide-react"

interface CustomerFormProps {
  customer?: Customer | null
  onClose: () => void
}

export function CustomerForm({ customer, onClose }: CustomerFormProps) {
  const [formData, setFormData] = useState({
    full_name: "",
    phone: "",
    id_number: "",
    address: "",
    loan_amount: "",
    interest_rate: "",
    loan_method: "scenario_a" as "scenario_a" | "scenario_b" | "scenario_c",
    deposit_amount: "",
    periods: "10",
    principal_rate_per_period: "10",
    number_of_periods: "10",
    notes: "",
    approval_status: "pending" as "pending" | "approved" | "rejected",
    contract_signed: false,
    negotiation_terms: "",
    loss_amount: "",
  })

  const [calculations, setCalculations] = useState({
    interest: 0,
    received_amount: 0,
    suggested_payment: 0,
    total_repayment: 0,
  })

  const [showContract, setShowContract] = useState(false)
  const [contractContent, setContractContent] = useState("")
  const [loading, setLoading] = useState(false)
  const supabase = createClient()

  // 生成客户代号
  const generateCustomerCode = async (): Promise<string> => {
    try {
      // 获取当前年份
      const currentYear = new Date().getFullYear().toString().slice(-2)
      
      // 获取当前客户数量
      const { count } = await supabase
        .from("customers")
        .select("*", { count: "exact", head: true })
      
      // 生成编号：年份 + 4位数字（从0001开始）
      const customerNumber = ((count || 0) + 1).toString().padStart(4, "0")
      return `C${currentYear}${customerNumber}`
    } catch (error) {
      console.error("生成客户代号失败:", error)
      // 如果出错，使用时间戳作为备用方案
      const timestamp = Date.now().toString().slice(-6)
      return `C${timestamp}`
    }
  }

  useEffect(() => {
    if (customer) {
      setFormData({
        full_name: customer.full_name || "",
      phone: customer.phone || "",
      id_number: customer.id_number || "",
        address: customer.address,
        loan_amount: customer.loan_amount?.toString() || "",
        interest_rate: customer.interest_rate?.toString() || "",
        loan_method: customer.loan_method || "scenario_a",
        deposit_amount: customer.deposit_amount?.toString() || "",
        periods: customer.periods?.toString() || "10",
        principal_rate_per_period: customer.principal_rate_per_period?.toString() || "10",
        number_of_periods: customer.number_of_periods?.toString() || "10",
        notes: customer.notes || "",
        approval_status: (customer as any).approval_status || "pending",
        contract_signed: (customer as any).contract_signed || false,
        negotiation_terms: (customer as any).negotiation_terms || "",
        loss_amount: ((customer as any).loss_amount || 0).toString(),
      })
    }
  }, [customer])

  useEffect(() => {
    calculateLoan()
  }, [
    formData.loan_amount,
    formData.interest_rate,
    formData.loan_method,
    formData.deposit_amount,
    formData.periods,
    formData.principal_rate_per_period,
    formData.number_of_periods,
  ])

  const calculateLoan = () => {
    const params: LoanCalculationParams = {
      loanAmount: Number.parseFloat(formData.loan_amount) || 0,
      interestRate: Number.parseFloat(formData.interest_rate) || 0,
      loanMethod: formData.loan_method,
      depositAmount: Number.parseFloat(formData.deposit_amount) || 0,
      numberOfPeriods: Number.parseInt(formData.number_of_periods) || 0,
      principalRatePerPeriod: Number.parseFloat(formData.principal_rate_per_period) || 0,
    }

    const result = LoanCalculator.calculate(params)

    setCalculations({
      interest: result.interest,
      received_amount: result.receivedAmount,
      suggested_payment: result.suggestedPayment,
      total_repayment: result.totalRepayment,
    })
  }

  const generateContract = async () => {
    try {
      const { data: template } = await supabase
        .from("contract_templates")
        .select("template_content")
        .eq("is_active", true)
        .single()

      if (template) {
        let content = template.template_content
        content = content.replace(/{customer_name}/g, formData.full_name)
        content = content.replace(/{id_number}/g, formData.id_number)
        content = content.replace(/{phone}/g, formData.phone)
        content = content.replace(/{address}/g, formData.address)
        content = content.replace(/{loan_amount}/g, formData.loan_amount)
        content = content.replace(/{interest_rate}/g, formData.interest_rate)
        content = content.replace(/{deposit_amount}/g, formData.deposit_amount)
        content = content.replace(/{received_amount}/g, calculations.received_amount.toString())
        const loanMethodText = formData.loan_method === "scenario_a" 
          ? "利息+押金" 
          : formData.loan_method === "scenario_b" 
            ? "只收利息" 
            : "只收押金"
        content = content.replace(/{loan_method_text}/g, loanMethodText)
        content = content.replace(/{additional_terms}/g, formData.notes)

        setContractContent(content)
        setShowContract(true)
      }
    } catch (error) {
      console.error("生成合同失败:", error)
    }
  }

  const signContract = () => {
    setFormData({ ...formData, contract_signed: true })
    setShowContract(false)
    alert("合同签署成功！")
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      // 如果是编辑客户，使用原有代号；如果是新客户，生成新代号
      const customerCode = customer ? customer.customer_code : await generateCustomerCode()

      const customerData = {
        customer_code: customerCode,
        full_name: formData.full_name, // 前端期望字段
        phone: formData.phone,
        id_number: formData.id_number, // 前端期望字段
        address: formData.address,
        notes: formData.notes,
        status: "normal", // 默认状态
        approval_status: formData.approval_status,
        contract_signed: formData.contract_signed,
        negotiation_terms: formData.negotiation_terms,
        loss_amount: Number.parseFloat(formData.loss_amount) || 0,
        // 添加贷款相关字段
        loan_amount: Number.parseFloat(formData.loan_amount) || 0,
        interest_rate: Number.parseFloat(formData.interest_rate) || 0,
        loan_method: formData.loan_method || "scenario_a",
        deposit_amount: Number.parseFloat(formData.deposit_amount) || 0,
        received_amount: calculations.received_amount || 0,
        suggested_payment: calculations.suggested_payment || 0,
        total_repayment: calculations.total_repayment || 0,
        periods: Number.parseInt(formData.periods) || 0,
        principal_rate_per_period: Number.parseFloat(formData.principal_rate_per_period) || 0,
        number_of_periods: Number.parseInt(formData.number_of_periods) || 0,
      }

      if (customer) {
        const { error } = await supabase.from("customers").update(customerData).eq("id", customer.id)
        if (error) throw error
      } else {
        const { error } = await supabase.from("customers").insert([customerData])
        if (error) throw error
      }

      onClose()
    } catch (error) {
      console.error("保存客户信息失败:", error)
      alert("保存失败，请重试")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-2 md:p-4 z-50 overflow-y-auto">
      <Card className="w-full max-w-5xl my-4 md:my-8 max-h-[calc(100vh-2rem)] md:max-h-[calc(100vh-4rem)] overflow-hidden bg-white border border-gray-200 shadow-xl rounded-lg">
        <CardHeader className="flex flex-row items-center justify-between p-3 md:p-6 bg-white border-b border-gray-200 sticky top-0 z-10">
          <CardTitle className="text-base md:text-xl font-semibold text-gray-900 truncate pr-2">{customer ? "编辑客户信息" : "添加新客户"}</CardTitle>
          <Button variant="ghost" size="sm" onClick={onClose} className="shrink-0 text-gray-600 hover:text-gray-900 hover:bg-gray-100 min-w-[2rem] h-8">
            <X className="w-4 h-4" />
          </Button>
        </CardHeader>

        <CardContent className="p-3 md:p-6 bg-white overflow-y-auto flex-1">
          <form onSubmit={handleSubmit} className="space-y-4 md:space-y-6">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 md:gap-6">
              {/* 基本信息 */}
              <div className="space-y-3 md:space-y-4">
                <h3 className="text-sm md:text-lg font-medium text-gray-900 border-b border-gray-200 pb-2">基本信息</h3>

                <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                  <div className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                    <span className="text-sm font-medium text-blue-800">客户代号</span>
                  </div>
                  <p className="text-xs text-blue-600 mt-1">
                    系统将自动生成唯一编号，格式：C{new Date().getFullYear().toString().slice(-2)}XXXX
                  </p>
                </div>

                <div>
                  <Label htmlFor="full_name" className="text-xs md:text-sm text-gray-700 font-medium">
                    客户姓名 *
                  </Label>
                  <Input
                    id="full_name"
                    value={formData.full_name}
                    onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                    className="mt-1 bg-white border-gray-300 text-gray-900 focus:border-blue-500 focus:ring-blue-500 text-sm md:text-base py-2.5 md:py-2"
                    placeholder="请输入客户姓名"
                    required
                  />
                </div>

                <div>
                  <Label htmlFor="phone" className="text-xs md:text-sm text-gray-700 font-medium">
                    手机号码 *
                  </Label>
                  <Input
                    id="phone"
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    placeholder="例如：+60123456789"
                    className="mt-1 bg-white border-gray-300 text-gray-900 placeholder-gray-500 focus:border-blue-500 focus:ring-blue-500 text-sm md:text-base py-2.5 md:py-2"
                    maxLength={15}
                    required
                  />
                </div>

                <div>
                  <Label htmlFor="id_number" className="text-xs md:text-sm text-gray-700 font-medium">
                    身份证号 *
                  </Label>
                  <Input
                    id="id_number"
                    value={formData.id_number}
                    onChange={(e) => setFormData({ ...formData, id_number: e.target.value })}
                    className="mt-1 bg-white border-gray-300 text-gray-900 focus:border-blue-500 focus:ring-blue-500 text-sm md:text-base py-2.5 md:py-2"
                    placeholder="请输入身份证号码"
                    maxLength={20}
                    required
                  />
                </div>

                <div>
                  <Label htmlFor="address" className="text-sm md:text-base text-gray-700 font-medium">
                    地址 *
                  </Label>
                  <Textarea
                    id="address"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    className="mt-1 min-h-[80px] bg-white border-gray-300 text-gray-900 placeholder-gray-500 focus:border-blue-500 focus:ring-blue-500"
                    required
                  />
                </div>

                <div>
                  <Label htmlFor="approval_status" className="text-sm md:text-base text-gray-700 font-medium">
                    审核状态
                  </Label>
                  <select
                    id="approval_status"
                    value={formData.approval_status}
                    onChange={(e) => setFormData({ ...formData, approval_status: e.target.value as any })}
                    className="w-full px-3 py-2 mt-1 border border-gray-300 rounded-md bg-white text-gray-900 text-sm md:text-base focus:border-blue-500 focus:ring-blue-500"
                  >
                    <option value="pending">待审核</option>
                    <option value="approved">已批准</option>
                    <option value="rejected">已拒绝</option>
                  </select>
                </div>
              </div>

              {/* 贷款信息 */}
              <div className="space-y-3 md:space-y-4">
                <h3 className="text-sm md:text-lg font-medium text-gray-900 border-b border-gray-200 pb-2">贷款信息</h3>

                <div>
                  <Label htmlFor="loan_method" className="text-sm md:text-base text-gray-700 font-medium">
                    贷款模式 *
                  </Label>
                  <select
                    id="loan_method"
                    value={formData.loan_method}
                    onChange={(e) => setFormData({ ...formData, loan_method: e.target.value as "scenario_a" | "scenario_b" | "scenario_c" })}
                    className="w-full px-3 py-2 mt-1 border border-gray-300 rounded-md bg-white text-gray-900 text-sm md:text-base focus:border-blue-500 focus:ring-blue-500"
                    required
                  >
                    <option value="scenario_a">场景A：利息+押金</option>
                    <option value="scenario_b">场景B：只收利息</option>
                    <option value="scenario_c">场景C：只收押金</option>
                  </select>
                </div>

                <div>
                  <Label htmlFor="loan_amount" className="text-xs md:text-sm text-gray-700 font-medium">
                    借款金额 (RM) *
                  </Label>
                  <Input
                    id="loan_amount"
                    type="number"
                    step="0.01"
                    inputMode="decimal"
                    value={formData.loan_amount}
                    onChange={(e) => setFormData({ ...formData, loan_amount: e.target.value })}
                    className="mt-1 bg-white border-gray-300 text-gray-900 focus:border-blue-500 focus:ring-blue-500 text-sm md:text-base py-2.5 md:py-2"
                    placeholder="请输入借款金额"
                    min="0"
                    required
                  />
                </div>

                <div>
                  <Label htmlFor="interest_rate" className="text-xs md:text-sm text-gray-700 font-medium">
                    利息比例 (%) *
                  </Label>
                  <Input
                    id="interest_rate"
                    type="number"
                    step="0.01"
                    inputMode="decimal"
                    value={formData.interest_rate}
                    onChange={(e) => setFormData({ ...formData, interest_rate: e.target.value })}
                    className="mt-1 bg-white border-gray-300 text-gray-900 focus:border-blue-500 focus:ring-blue-500 text-sm md:text-base py-2.5 md:py-2"
                    placeholder="请输入利息比例"
                    min="0"
                    max="100"
                    required
                  />
                </div>

                <div>
                  <Label htmlFor="deposit_amount" className="text-xs md:text-sm text-gray-700 font-medium">
                    抵押金额 (RM)
                  </Label>
                  <Input
                    id="deposit_amount"
                    type="number"
                    step="0.01"
                    inputMode="decimal"
                    value={formData.deposit_amount}
                    onChange={(e) => setFormData({ ...formData, deposit_amount: e.target.value })}
                    className="mt-1 bg-white border-gray-300 text-gray-900 focus:border-blue-500 focus:ring-blue-500 text-sm md:text-base py-2.5 md:py-2"
                    placeholder="请输入抵押金额"
                    min="0"
                  />
                </div>

                <div>
                  <Label htmlFor="negotiation_terms" className="text-sm md:text-base text-gray-700 font-medium">
                    谈帐条件
                  </Label>
                  <Textarea
                    id="negotiation_terms"
                    value={formData.negotiation_terms}
                    onChange={(e) => setFormData({ ...formData, negotiation_terms: e.target.value })}
                    placeholder=""
                    className="mt-1 min-h-[60px] bg-white border-gray-300 text-gray-900 placeholder-gray-500 focus:border-blue-500 focus:ring-blue-500"
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
                  <Label htmlFor="notes" className="text-sm md:text-base text-gray-700 font-medium">
                    备注
                  </Label>
                  <Textarea
                    id="notes"
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    placeholder=""
                    className="mt-1 min-h-[60px] bg-white border-gray-300 text-gray-900 placeholder-gray-500 focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>

            {/* 计算预览 */}
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 md:p-4">
              <div className="flex items-center space-x-2 mb-3 md:mb-4">
                <Calculator className="w-4 h-4 md:w-5 md:h-5 text-blue-600" />
                <h3 className="text-base md:text-lg font-medium text-gray-900">计算预览</h3>
              </div>

              <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 md:gap-4">
                <div className="text-center">
                  <div className="text-lg md:text-2xl font-bold text-blue-600">
                    RM {calculations.received_amount.toLocaleString()}
                  </div>
                  <div className="text-xs md:text-sm text-gray-600">到手现金</div>
                </div>
                <div className="text-center">
                  <div className="text-lg md:text-2xl font-bold text-green-600">
                    RM {calculations.interest.toLocaleString()}
                  </div>
                  <div className="text-xs md:text-sm text-gray-600">利息金额</div>
                </div>
                <div className="text-center">
                  <div className="text-lg md:text-2xl font-bold text-orange-600">
                    RM {calculations.suggested_payment.toLocaleString()}
                  </div>
                  <div className="text-xs md:text-sm text-gray-600">建议每期还款</div>
                </div>
                <div className="text-center">
                  <div className="text-lg md:text-2xl font-bold text-gray-900">
                    RM {calculations.total_repayment.toLocaleString()}
                  </div>
                  <div className="text-xs md:text-sm text-gray-600">总还款金额</div>
                </div>
              </div>
            </div>

            {/* 合同管理区域 */}
            <div className="bg-green-50 border border-green-200 rounded-lg p-3 md:p-4">
              <div className="flex flex-col space-y-3 md:flex-row md:items-center md:justify-between md:space-y-0 mb-3 md:mb-4">
                <div className="flex items-center space-x-2">
                  <FileText className="w-4 h-4 md:w-5 md:h-5 text-green-600" />
                  <h3 className="text-base md:text-lg font-medium text-gray-900">电子合同</h3>
                </div>
                <div className="flex items-center justify-between md:justify-end space-x-2">
                  {formData.contract_signed && (
                    <div className="flex items-center space-x-1 text-green-600">
                      <CheckCircle className="w-4 h-4" />
                      <span className="text-xs md:text-sm">已签署</span>
                    </div>
                  )}
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={generateContract}
                    disabled={!formData.full_name || !formData.loan_amount}
                    className="text-xs md:text-sm bg-white border-gray-300 text-gray-900 hover:bg-gray-50 hover:border-gray-400 disabled:bg-gray-100 disabled:text-gray-400"
                  >
                    生成合同
                  </Button>
                </div>
              </div>
            </div>

            {/* 提交按钮 */}
            <div className="sticky bottom-0 bg-white border-t border-gray-200 p-3 md:p-4 -mx-3 md:-mx-6 -mb-3 md:-mb-6 mt-4 md:mt-6">
              <div className="flex flex-col-reverse sm:flex-row justify-end gap-2 sm:gap-3">
                <Button 
                  type="button" 
                  variant="outline" 
                  onClick={onClose} 
                  className="w-full sm:w-auto px-4 md:px-6 py-2.5 md:py-2 text-sm md:text-base text-gray-700 border-gray-300 hover:bg-gray-50 hover:text-gray-900"
                >
                  取消
                </Button>
                <Button 
                  type="submit" 
                  disabled={loading} 
                  className="w-full sm:w-auto px-4 md:px-6 py-2.5 md:py-2 text-sm md:text-base bg-blue-600 hover:bg-blue-700 text-white border-blue-600 hover:border-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {loading ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                      保存中...
                    </>
                  ) : (
                    customer ? "更新客户" : "添加客户"
                  )}
                </Button>
              </div>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* 合同预览弹窗 */}
      {showContract && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-2 md:p-4 z-60">
          <Card className="w-full max-w-4xl max-h-[95vh] md:max-h-[90vh] overflow-y-auto bg-white border border-gray-200 shadow-xl">
            <CardHeader className="flex flex-row items-center justify-between p-4 md:p-6 bg-white border-b border-gray-200">
              <CardTitle className="text-base md:text-lg text-gray-900">电子合同预览</CardTitle>
              <Button variant="ghost" size="sm" onClick={() => setShowContract(false)} className="text-gray-600 hover:text-gray-900 hover:bg-gray-100">
                <X className="w-4 h-4" />
              </Button>
            </CardHeader>
            <CardContent className="p-4 md:p-6 bg-white">
              <div className="whitespace-pre-wrap text-xs md:text-sm mb-4 md:mb-6 p-3 md:p-4 bg-gray-50 border border-gray-200 rounded-lg max-h-60 md:max-h-80 overflow-y-auto text-gray-900">
                {contractContent}
              </div>
              <div className="flex flex-col space-y-3 md:flex-row md:items-center md:justify-end md:space-y-0 md:space-x-4">
                <Button variant="outline" onClick={() => setShowContract(false)} className="w-full md:w-auto bg-white border-gray-300 text-gray-900 hover:bg-gray-50 hover:border-gray-400">
                  取消
                </Button>
                <Button onClick={signContract} className="w-full md:w-auto bg-green-600 hover:bg-green-700 text-white">
                  确认签署
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}
