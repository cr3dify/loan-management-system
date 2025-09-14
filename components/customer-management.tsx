"use client"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import type { Customer } from "@/lib/types"
import { CustomerList } from "./customer-list"
import { CustomerForm } from "./customer-form"
import { Button } from "@/components/ui/button"
import { Plus } from "lucide-react"

export function CustomerManagement() {
  const [customers, setCustomers] = useState<Customer[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editingCustomer, setEditingCustomer] = useState<Customer | null>(null)
  const supabase = createClient()

  useEffect(() => {
    fetchCustomers()
  }, [])

  const fetchCustomers = async () => {
    try {
      const { data, error } = await supabase.from("customers").select("*").order("created_at", { ascending: false })

      if (error) throw error
      
            // 映射数据库字段到类型定义
            const mappedCustomers = (data || []).map((customer: any) => ({
              ...customer,
              full_name: customer.full_name || "",
              id_number: customer.id_number || "",
              // 添加默认值以防止错误
              loan_amount: Number(customer.loan_amount) || 0,
              interest_rate: Number(customer.interest_rate) || 0,
              deposit_amount: Number(customer.deposit_amount) || 0,
              received_amount: Number(customer.received_amount) || 0,
              suggested_payment: Number(customer.suggested_payment) || 0,
              total_repayment: Number(customer.total_repayment) || 0,
              periods: Number(customer.periods) || 0,
              principal_rate_per_period: Number(customer.principal_rate_per_period) || 0,
              number_of_periods: Number(customer.number_of_periods) || 0,
              status: customer.status || "normal",
              notes: customer.notes || "",
              approval_status: customer.approval_status || "pending",
              contract_signed: Boolean(customer.contract_signed),
              negotiation_terms: customer.negotiation_terms || "",
              loss_amount: Number(customer.loss_amount) || 0,
            }))
      
      setCustomers(mappedCustomers)
    } catch (error) {
      console.error("获取客户列表失败:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleAddCustomer = () => {
    setEditingCustomer(null)
    setShowForm(true)
  }

  const handleEditCustomer = (customer: Customer) => {
    setEditingCustomer(customer)
    setShowForm(true)
  }

  const handleFormClose = () => {
    setShowForm(false)
    setEditingCustomer(null)
    fetchCustomers()
  }

  const handleUpdateCustomer = async (customerId: string, field: string, value: string) => {
    try {
      const { error } = await supabase
        .from("customers")
        .update({ [field]: value })
        .eq("id", customerId)

      if (error) throw error

      // 更新本地状态
      setCustomers(prev => 
        prev.map(customer => 
          customer.id === customerId 
            ? { ...customer, [field]: value }
            : customer
        )
      )
    } catch (error) {
      console.error("更新客户失败:", error)
      alert("更新失败，请重试")
    }
  }

  const handleDeleteCustomer = async (customerId: string) => {
    try {
      // 先删除相关的还款记录
      const { error: repaymentsError } = await supabase
        .from("repayments")
        .delete()
        .eq("customer_id", customerId)

      if (repaymentsError) {
        console.warn("删除还款记录失败:", repaymentsError)
        // 继续删除客户，不阻止操作
      }

      // 删除客户
      const { error } = await supabase
        .from("customers")
        .delete()
        .eq("id", customerId)

      if (error) throw error

      // 从本地状态中移除
      setCustomers(prev => prev.filter(customer => customer.id !== customerId))
      
      alert("客户删除成功")
    } catch (error) {
      console.error("删除客户失败:", error)
      alert("删除失败，请重试")
      throw error // 重新抛出错误，让对话框知道操作失败
    }
  }

  return (
    <div className="space-y-6">
        <div className="flex flex-col space-y-4 mb-6 md:flex-row md:items-center md:justify-between md:space-y-0 md:mb-8">
          <div>
            <h1 className="text-2xl md:text-3xl font-bold text-foreground mb-2">客户管理</h1>
            <p className="text-sm md:text-base text-muted-foreground">管理所有客户信息和贷款记录</p>
          </div>
          <Button
            onClick={handleAddCustomer}
            className="bg-primary hover:bg-primary/90 text-primary-foreground w-full md:w-auto"
          >
            <Plus className="w-4 h-4 mr-2" />
            添加客户
          </Button>
        </div>

        <CustomerList
          customers={customers}
          loading={loading}
          onEditCustomer={handleEditCustomer}
          onRefresh={fetchCustomers}
          onUpdateCustomer={handleUpdateCustomer}
          onDeleteCustomer={handleDeleteCustomer}
        />

        {showForm && <CustomerForm customer={editingCustomer} onClose={handleFormClose} />}
    </div>
  )
}
