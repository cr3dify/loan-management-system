"use client"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import type { Customer, Repayment } from "@/lib/types"
import { RepaymentList } from "./repayment-list"
import { RepaymentForm } from "./repayment-form"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Plus, Search, CreditCard } from "lucide-react"

export function RepaymentManagement() {
  const [repayments, setRepayments] = useState<(Repayment & { customer: Customer })[]>([])
  const [customers, setCustomers] = useState<Customer[]>([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null)
  const [searchTerm, setSearchTerm] = useState("")
  const supabase = createClient()

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      // 获取还款记录
      const { data: repaymentData, error: repaymentError } = await supabase
        .from("repayments")
        .select(`
          *,
          customer:customers(*)
        `)
        .order("payment_date", { ascending: false })

      if (repaymentError) throw repaymentError

      // 获取客户列表
      const { data: customerData, error: customerError } = await supabase
        .from("customers")
        .select("*")
        .neq("status", "cleared")
        .order("full_name")

      if (customerError) throw customerError

      setRepayments(repaymentData || [])
      setCustomers(customerData || [])
    } catch (error) {
      console.error("获取数据失败:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleAddRepayment = (customer?: Customer) => {
    setSelectedCustomer(customer || null)
    setShowForm(true)
  }

  const handleFormClose = () => {
    setShowForm(false)
    setSelectedCustomer(null)
    fetchData()
  }

  const filteredCustomers = customers.filter(
    (customer) =>
      customer.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      customer.customer_code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      customer.phone.includes(searchTerm),
  )

  return (
    <main className="container mx-auto px-4 py-8">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-foreground mb-2">还款管理</h1>
            <p className="text-muted-foreground">管理客户还款记录和逾期处理</p>
          </div>
          <Button
            onClick={() => handleAddRepayment()}
            className="bg-primary hover:bg-primary/90 text-primary-foreground"
          >
            <Plus className="w-4 h-4 mr-2" />
            添加还款
          </Button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* 客户选择 */}
          <div className="lg:col-span-1">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <CreditCard className="w-5 h-5 text-primary" />
                  <span>选择客户</span>
                </CardTitle>
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground w-4 h-4" />
                  <Input
                    placeholder="搜索客户..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-10"
                  />
                </div>
              </CardHeader>
              <CardContent className="max-h-96 overflow-y-auto">
                {loading ? (
                  <div className="text-center py-4 text-muted-foreground">加载中...</div>
                ) : filteredCustomers.length === 0 ? (
                  <div className="text-center py-4 text-muted-foreground">
                    {searchTerm ? "未找到匹配的客户" : "暂无客户"}
                  </div>
                ) : (
                  <div className="space-y-2">
                    {filteredCustomers.map((customer) => (
                      <div
                        key={customer.id}
                        className={`p-3 border border-border rounded-lg cursor-pointer hover:bg-muted/50 transition-colors ${
                          customer.status === "overdue" ? "border-orange-200 bg-orange-50" : ""
                        }`}
                        onClick={() => handleAddRepayment(customer)}
                      >
                        <div className="flex items-center justify-between">
                          <div>
                            <div className="font-medium">{customer.full_name}</div>
                            <div className="text-sm text-muted-foreground">{customer.customer_code}</div>
                          </div>
                          <div className="text-right">
                            <div className="text-sm font-medium">RM {(customer.loan_amount || 0).toLocaleString()}</div>
                            <div
                              className={`text-xs px-2 py-1 rounded-full ${
                                customer.status === "normal"
                                  ? "bg-gray-100 text-gray-800"
                                  : customer.status === "overdue"
                                    ? "bg-orange-100 text-orange-800"
                                    : customer.status === "negotiating"
                                      ? "bg-yellow-100 text-yellow-800"
                                      : "bg-red-100 text-red-800"
                              }`}
                            >
                              {customer.status === "normal"
                                ? "正常"
                                : customer.status === "overdue"
                                  ? "逾期"
                                  : customer.status === "negotiating"
                                    ? "谈帐"
                                    : "烂账"}
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* 还款记录 */}
          <div className="lg:col-span-2">
            <RepaymentList repayments={repayments} loading={loading} onRefresh={fetchData} />
          </div>
        </div>

        {showForm && <RepaymentForm customer={selectedCustomer} onClose={handleFormClose} />}
    </main>
  )
}
