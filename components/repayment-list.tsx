"use client"

import type { Customer, Repayment } from "@/lib/types"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { RefreshCw, Receipt, Calendar } from "lucide-react"

interface RepaymentListProps {
  repayments: (Repayment & { customer: Customer })[]
  loading: boolean
  onRefresh: () => void
}

export function RepaymentList({ repayments, loading, onRefresh }: RepaymentListProps) {
  const getPaymentTypeBadge = (type: string) => {
    const typeMap = {
      interest_only: { label: "只还利息", className: "bg-purple-100 text-purple-800" },
      partial_principal: { label: "部分还款", className: "bg-yellow-100 text-yellow-800" },
      full_settlement: { label: "全额结清", className: "bg-green-100 text-green-800" },
    }

    const typeInfo = typeMap[type as keyof typeof typeMap] || typeMap.partial_principal
    return <Badge className={typeInfo.className}>{typeInfo.label}</Badge>
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("zh-CN")
  }

  if (loading) {
    return (
      <Card>
        <CardContent className="p-8">
          <div className="flex items-center justify-center">
            <RefreshCw className="w-6 h-6 animate-spin text-primary mr-2" />
            <span className="text-muted-foreground">加载中...</span>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center space-x-2">
            <Receipt className="w-5 h-5 text-primary" />
            <span>还款记录</span>
          </CardTitle>
          <Button
            variant="outline"
            size="sm"
            onClick={onRefresh}
            className="flex items-center space-x-2 bg-transparent"
          >
            <RefreshCw className="w-4 h-4" />
            <span>刷新</span>
          </Button>
        </div>
      </CardHeader>

      <CardContent>
        {repayments.length === 0 ? (
          <div className="text-center py-8 text-muted-foreground">暂无还款记录</div>
        ) : (
          <div className="space-y-4">
            {repayments.map((repayment) => (
              <div
                key={repayment.id}
                className="border border-border rounded-lg p-4 hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center space-x-3">
                    <div>
                      <div className="font-medium">{repayment.customer.full_name}</div>
                      <div className="text-sm text-muted-foreground">{repayment.customer.customer_code}</div>
                    </div>
                    {getPaymentTypeBadge(repayment.repayment_type)}
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold text-primary">RM {repayment.amount.toLocaleString()}</div>
                    <div className="flex items-center text-sm text-muted-foreground">
                      <Calendar className="w-3 h-3 mr-1" />
                      {formatDate(repayment.payment_date)}
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-4 text-sm">
                  <div>
                    <div className="text-muted-foreground">本金</div>
                    <div className="font-medium">RM {(repayment.principal_amount || 0).toLocaleString()}</div>
                  </div>
                  <div>
                    <div className="text-muted-foreground">利息</div>
                    <div className="font-medium">RM {(repayment.interest_amount || 0).toLocaleString()}</div>
                  </div>
                  <div>
                    <div className="text-muted-foreground">罚金</div>
                    <div className="font-medium">RM {(repayment.penalty_amount || 0).toLocaleString()}</div>
                  </div>
                </div>

                {repayment.penalty_amount && repayment.penalty_amount > 0 && (
                  <div className="mt-2 p-2 bg-orange-50 border border-orange-200 rounded">
                    <div className="text-sm text-orange-800">罚金: RM {repayment.penalty_amount.toLocaleString()}</div>
                  </div>
                )}

                {repayment.notes && <div className="mt-2 text-sm text-muted-foreground">备注: {repayment.notes}</div>}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
