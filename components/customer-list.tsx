"use client"

import { useState } from "react"
import type { Customer } from "@/lib/types"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Search, Edit, Eye, RefreshCw, FileText, CheckCircle, Clock, XCircle, Phone, Trash2, Users, TrendingUp, DollarSign, AlertCircle, Filter, ChevronDown } from "lucide-react"
import { InlineEdit } from "./inline-edit"
import { DeleteConfirmationDialog } from "./delete-confirmation-dialog"
import { usePermissions } from "@/hooks/use-permissions"
import { createClient } from "@/lib/supabase/client"

interface CustomerListProps {
  customers: Customer[]
  loading: boolean
  onEditCustomer: (customer: Customer) => void
  onRefresh: () => void
  onUpdateCustomer?: (customerId: string, field: string, value: string) => Promise<void> // 修改为 string 类型
  onDeleteCustomer?: (customerId: string) => Promise<void> // 修改为 string 类型
}

export function CustomerList({ customers, loading, onEditCustomer, onRefresh, onUpdateCustomer, onDeleteCustomer }: CustomerListProps) {
  const [searchTerm, setSearchTerm] = useState("")
  const [statusFilter, setStatusFilter] = useState<string>("all")
  const [deleteDialog, setDeleteDialog] = useState<{ isOpen: boolean; customer: Customer | null }>({
    isOpen: false,
    customer: null
  })
  const [editingStatus, setEditingStatus] = useState<{ customerId: string; field: string; currentValue: string } | null>(null)
  const permissions = usePermissions()
  const supabase = createClient()



  const filteredCustomers = customers.filter((customer) => {
    const matchesSearch = (
      customer.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      customer.customer_code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      customer.phone.includes(searchTerm)
    )
    
    const matchesStatus = statusFilter === "all" || customer.status === statusFilter
    
    return matchesSearch && matchesStatus
  })

  // 获取客户统计数据
  const getCustomerStats = () => {
    const total = customers.length
    const normal = customers.filter(c => c.status === 'normal').length
    const cleared = customers.filter(c => c.status === 'cleared').length
    const overdue = customers.filter(c => c.status === 'overdue').length
    const totalAmount = customers.reduce((sum, c) => sum + (c.loan_amount || 0), 0)
    
    return { total, normal, cleared, overdue, totalAmount }
  }

  const stats = getCustomerStats()

  const getStatusBadge = (status: string, isClickable = false, onClick?: () => void) => {
    const statusMap = {
      normal: { label: "正常", className: "bg-primary-50 text-primary-700 border-primary-200" },
      cleared: { label: "清完", className: "bg-success-50 text-success-700 border-success-200" },
      negotiating: { label: "谈帐", className: "bg-warning-50 text-warning-700 border-warning-200" },
      bad_debt: { label: "烂账", className: "bg-error-50 text-error-700 border-error-200" },
      overdue: { label: "逾期", className: "bg-orange-50 text-orange-700 border-orange-200" },
    }

    const statusInfo = statusMap[status as keyof typeof statusMap] || statusMap.normal
    return (
      <Badge 
        className={`modern-badge ${statusInfo.className} ${
          isClickable ? 'cursor-pointer hover:shadow-md transition-all duration-200' : ''
        }`}
        onClick={isClickable ? onClick : undefined}
        title={isClickable ? '点击编辑状态' : undefined}
      >
        {statusInfo.label}
      </Badge>
    )
  }

  const getApprovalBadge = (approvalStatus: string) => {
    const statusMap = {
      pending: { label: "待审核", className: "bg-blue-50 text-blue-700 border-blue-200", icon: Clock },
      approved: { label: "已批准", className: "bg-success-50 text-success-700 border-success-200", icon: CheckCircle },
      rejected: { label: "已拒绝", className: "bg-error-50 text-error-700 border-error-200", icon: XCircle },
    }

    const statusInfo = statusMap[approvalStatus as keyof typeof statusMap] || statusMap.pending
    const IconComponent = statusInfo.icon
    return (
      <Badge className={`modern-badge ${statusInfo.className} flex items-center gap-1.5`}>
        <IconComponent className="w-3 h-3" />
        <span>{statusInfo.label}</span>
      </Badge>
    )
  }

  const getRowClassName = (status: string) => {
    const statusClasses = {
      normal: "row-normal",
      cleared: "row-cleared", 
      negotiating: "row-negotiating",
      bad_debt: "row-bad-debt",
      overdue: "row-overdue",
    }
    return statusClasses[status as keyof typeof statusClasses] || "row-normal"
  }

  const statusOptions = [
    { value: "normal", label: "正常" },
    { value: "cleared", label: "清完" },
    { value: "negotiating", label: "谈帐" },
    { value: "bad_debt", label: "烂账" },
    { value: "overdue", label: "逾期" },
  ]

  const approvalStatusOptions = [
    { value: "pending", label: "待审核" },
    { value: "approved", label: "已批准" },
    { value: "rejected", label: "已拒绝" },
  ]

  const handleStatusUpdate = async (customerId: string, field: string, value: string) => {
    try {
      console.log('开始更新客户状态:', { customerId, field, value })
      
      // 验证输入参数
      if (!customerId || !field || !value || value.trim() === '') {
        throw new Error('缺少必要的更新参数')
      }

      // 验证字段名
      const allowedFields = ['status', 'approval_status']
      if (!allowedFields.includes(field)) {
        throw new Error(`不允许更新字段: ${field}`)
      }

      // 验证状态值
      const statusValues = {
        status: ['normal', 'overdue', 'cleared', 'negotiating', 'bad_debt'],
        approval_status: ['pending', 'approved', 'rejected']
      }
      
      const validValues = statusValues[field as keyof typeof statusValues]
      console.log('验证状态值:', { field, value, validValues, isValid: validValues.includes(value) })
      
      if (!validValues.includes(value)) {
        console.error('状态值验证失败:', { field, value, validValues })
        throw new Error(`无效的${field}值: ${value}，允许的值: ${validValues.join(', ')}`)
      }

      // 构建更新数据 - 只更新指定字段
      const updateData: Record<string, any> = {
        [field]: value
      }

      console.log('准备更新数据库:', { customerId, updateData })

      // 直接更新数据库 - 只更新指定字段，避免触发其他约束
      const { data, error } = await supabase
        .from('customers')
        .update(updateData)
        .eq('id', customerId)
        .select(`id, ${field}`)

      if (error) {
        console.error('Supabase更新错误:', error)
        throw new Error(`数据库更新失败: ${error.message}`)
      }

      console.log('更新成功:', data)

      // 调用父组件的更新函数（如果存在）来刷新本地状态
      if (onUpdateCustomer) {
        try {
          await onUpdateCustomer(customerId, field, value)
        } catch (parentError) {
          console.warn('父组件更新函数执行失败:', parentError)
          // 不抛出错误，因为数据库更新已经成功
        }
      }
      
      // 刷新数据
      onRefresh()
      
    } catch (error) {
      console.error('更新客户状态失败:', error)
      // 重新抛出更详细的错误信息
      if (error instanceof Error) {
        throw error
      } else {
        throw new Error('更新失败，请重试')
      }
    }
  }

  const handleDeleteClick = (customer: Customer) => {
    setDeleteDialog({ isOpen: true, customer })
  }

  const handleDeleteConfirm = async () => {
    if (deleteDialog.customer && onDeleteCustomer) {
      await onDeleteCustomer(deleteDialog.customer.id)
      setDeleteDialog({ isOpen: false, customer: null })
    }
  }

  const handleDeleteCancel = () => {
    setDeleteDialog({ isOpen: false, customer: null })
  }

  if (loading) {
    return (
      <div className="modern-card">
        <div className="modern-card-content">
          <div className="flex items-center justify-center py-12">
            <div className="flex flex-col items-center gap-3">
              <RefreshCw className="w-8 h-8 animate-spin text-primary-500" />
              <span className="text-neutral-600 font-medium">加载中...</span>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* 现代化统计卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="modern-stat-card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-neutral-600">总客户数</p>
              <p className="text-2xl font-bold text-neutral-900">{stats.total}</p>
            </div>
            <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center">
              <Users className="w-6 h-6 text-primary-600" />
            </div>
          </div>
        </div>
        
        <div className="modern-stat-card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-neutral-600">正常客户</p>
              <p className="text-2xl font-bold text-primary-600">{stats.normal}</p>
            </div>
            <div className="w-12 h-12 bg-success-100 rounded-xl flex items-center justify-center">
              <CheckCircle className="w-6 h-6 text-success-600" />
            </div>
          </div>
        </div>
        
        <div className="modern-stat-card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-neutral-600">逾期客户</p>
              <p className="text-2xl font-bold text-warning-600">{stats.overdue}</p>
            </div>
            <div className="w-12 h-12 bg-warning-100 rounded-xl flex items-center justify-center">
              <AlertCircle className="w-6 h-6 text-warning-600" />
            </div>
          </div>
        </div>
        
        <div className="modern-stat-card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-neutral-600">贷款总额</p>
              <p className="text-2xl font-bold text-success-600">RM {stats.totalAmount.toLocaleString()}</p>
            </div>
            <div className="w-12 h-12 bg-primary-100 rounded-xl flex items-center justify-center">
              <TrendingUp className="w-6 h-6 text-primary-600" />
            </div>
          </div>
        </div>
      </div>

      {/* 现代化客户列表 */}
      <div className="modern-card">
        <div className="modern-card-header">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-primary-100 rounded-lg flex items-center justify-center">
                <Users className="w-4 h-4 text-primary-600" />
              </div>
              <h3 className="modern-card-title">客户列表</h3>
              <Badge className="modern-badge bg-neutral-100 text-neutral-700 border-neutral-200">
                {filteredCustomers.length} 人
              </Badge>
            </div>
            
            <div className="flex items-center gap-3">
              <Button
                variant="outline"
                size="sm"
                onClick={onRefresh}
                className="modern-btn modern-btn-outline"
              >
                <RefreshCw className="w-4 h-4 mr-2" />
                刷新
              </Button>
            </div>
          </div>

          {/* 现代化搜索和过滤 */}
          <div className="flex flex-col gap-4 mt-6 lg:flex-row lg:items-center">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-neutral-400 w-4 h-4" />
              <Input
                placeholder="搜索客户姓名、代号或电话..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="modern-input pl-10"
              />
            </div>
            
            <div className="relative">
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="modern-select w-full lg:w-auto"
              >
                <option value="all">所有状态</option>
                <option value="normal">正常</option>
                <option value="cleared">清完</option>
                <option value="negotiating">谈帐</option>
                <option value="overdue">逾期</option>
                <option value="bad_debt">烂账</option>
              </select>
              <Filter className="absolute right-3 top-1/2 transform -translate-y-1/2 text-neutral-400 w-4 h-4 pointer-events-none" />
            </div>
          </div>
        </div>

        <div className="modern-card-content">
          {filteredCustomers.length === 0 ? (
            <div className="text-center py-12">
              <div className="w-16 h-16 bg-neutral-100 rounded-xl flex items-center justify-center mx-auto mb-4">
                <Users className="w-8 h-8 text-neutral-400" />
              </div>
              <p className="text-neutral-600 text-lg font-medium mb-2">
                {searchTerm || statusFilter !== "all" ? "未找到匹配的客户" : "暂无客户数据"}
              </p>
              <p className="text-neutral-500 text-sm">
                {searchTerm || statusFilter !== "all" ? "请尝试调整搜索条件或过滤器" : "添加新客户开始管理"}
              </p>
            </div>
          ) : (
            <>
              {/* 移动端卡片视图 */}
              <div className="block lg:hidden space-y-4">
                {filteredCustomers.map((customer) => (
                  <div key={customer.id} className="modern-customer-card">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <div className="w-10 h-10 bg-primary-100 rounded-lg flex items-center justify-center">
                            <Users className="w-5 h-5 text-primary-600" />
                          </div>
                          <div>
                            <h3 className="font-semibold text-neutral-900 text-lg">
                              {customer.full_name || "未知客户"}
                            </h3>
                            <p className="text-sm text-neutral-600">
                              {customer.customer_code} • {customer.customer_number}
                            </p>
                          </div>
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-2">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => onEditCustomer(customer)}
                          className="w-8 h-8 p-0 text-primary-600 hover:bg-primary-50"
                        >
                          <Edit className="w-4 h-4" />
                        </Button>
                        <Button 
                          variant="ghost" 
                          size="sm" 
                          className="w-8 h-8 p-0 text-neutral-600 hover:bg-neutral-50"
                        >
                          <Eye className="w-4 h-4" />
                        </Button>
                      </div>
                    </div>

                    <div className="space-y-3">
                      <div className="flex items-center gap-2 text-sm text-neutral-700">
                        <Phone className="w-4 h-4 text-primary-600" />
                        <span className="font-medium">{customer.phone}</span>
                      </div>

                      <div className="flex items-center justify-between py-2 px-3 bg-neutral-50 rounded-lg">
                        <span className="text-sm font-medium text-neutral-700">贷款金额:</span>
                        <span className="font-bold text-neutral-900">RM {(customer.loan_amount || 0).toLocaleString()}</span>
                      </div>

                      <div className="flex flex-wrap gap-2">
                        <InlineEdit
                          value={(customer as any).approval_status || "pending"}
                          options={approvalStatusOptions}
                          onSave={(value) => handleStatusUpdate(customer.id, "approval_status", value)}
                          fieldName="approval_status"
                          className="text-xs"
                        />
                        
                        {(customer as any).contract_signed ? (
                          <Badge className="modern-badge bg-success-50 text-success-700 border-success-200 flex items-center gap-1.5">
                            <FileText className="w-3 h-3" />
                            <span>已签署</span>
                          </Badge>
                        ) : (
                          <Badge className="modern-badge bg-neutral-50 text-neutral-700 border-neutral-200">未签署</Badge>
                        )}
                        
                        <InlineEdit
                          value={customer.status}
                          options={statusOptions}
                          onSave={(value) => handleStatusUpdate(customer.id, "status", value)}
                          fieldName="status"
                          className="text-xs"
                        />
                      </div>

                      {onDeleteCustomer && (
                        <div className="flex justify-end pt-2 border-t border-neutral-200">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleDeleteClick(customer)}
                            className="text-error-600 border-error-200 hover:bg-error-50 hover:border-error-300"
                          >
                            <Trash2 className="w-4 h-4 mr-2" />
                            删除
                          </Button>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              {/* 桌面端表格视图 */}
              <div className="hidden lg:block">
                <div className="modern-table-container">
                  <table className="modern-table">
                    <thead>
                      <tr>
                        <th className="modern-table-th">客户代号</th>
                        <th className="modern-table-th">客户编号</th>
                        <th className="modern-table-th">姓名</th>
                        <th className="modern-table-th">电话</th>
                        <th className="modern-table-th">贷款金额</th>
                        <th className="modern-table-th">审核状态</th>
                        <th className="modern-table-th">合同状态</th>
                        <th className="modern-table-th">客户状态</th>
                        <th className="modern-table-th">操作</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredCustomers.map((customer) => (
                        <tr key={customer.id} className={`modern-table-row ${getRowClassName(customer.status)}`}>
                          <td className="modern-table-td font-semibold text-neutral-900">
                            {customer.customer_code}
                          </td>
                          <td className="modern-table-td text-neutral-700">
                            {customer.customer_number}
                          </td>
                          <td className="modern-table-td font-semibold text-neutral-900">
                            {customer.full_name || "未知客户"}
                          </td>
                          <td className="modern-table-td text-neutral-700">
                            {customer.phone}
                          </td>
                          <td className="modern-table-td font-bold text-neutral-900">
                            RM {(customer.loan_amount || 0).toLocaleString()}
                          </td>
                          <td className="modern-table-td">
                            <InlineEdit
                              value={(customer as any).approval_status || "pending"}
                              options={approvalStatusOptions}
                              onSave={(value) => handleStatusUpdate(customer.id, "approval_status", value)}
                              fieldName="approval_status"
                              className="text-sm"
                            />
                          </td>
                          <td className="modern-table-td">
                            {(customer as any).contract_signed ? (
                              <Badge className="modern-badge bg-success-50 text-success-700 border-success-200 flex items-center gap-1.5">
                                <FileText className="w-3 h-3" />
                                <span>已签署</span>
                              </Badge>
                            ) : (
                              <Badge className="modern-badge bg-neutral-50 text-neutral-700 border-neutral-200">未签署</Badge>
                            )}
                          </td>
                          <td className="modern-table-td">
                            <InlineEdit
                              value={customer.status || "normal"}
                              options={statusOptions}
                              onSave={(value) => handleStatusUpdate(customer.id, "status", value)}
                              fieldName="status"
                              className="text-sm"
                            />
                          </td>
                          <td className="modern-table-td">
                            <div className="flex items-center gap-2">
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => onEditCustomer(customer)}
                                className="w-8 h-8 p-0 text-primary-600 hover:bg-primary-50"
                              >
                                <Edit className="w-4 h-4" />
                              </Button>
                              <Button 
                                variant="ghost" 
                                size="sm" 
                                className="w-8 h-8 p-0 text-neutral-600 hover:bg-neutral-50"
                              >
                                <Eye className="w-4 h-4" />
                              </Button>
                              {onDeleteCustomer && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => handleDeleteClick(customer)}
                                  className="w-8 h-8 p-0 text-error-600 hover:bg-error-50"
                                >
                                  <Trash2 className="w-4 h-4" />
                                </Button>
                              )}
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}
        </div>
      </div>

      <DeleteConfirmationDialog
        isOpen={deleteDialog.isOpen}
        onClose={handleDeleteCancel}
        onConfirm={handleDeleteConfirm}
        customerName={deleteDialog.customer?.full_name || "未知客户"}
        customerCode={deleteDialog.customer?.customer_code || ""}
      />
    </div>
  )
}
