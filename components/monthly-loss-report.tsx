"use client"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { TrendingDown, Calendar, DollarSign, Users } from "lucide-react"

interface MonthlyLoss {
  id: string
  year: number
  month: number
  total_loss_amount: number
  bad_debt_count: number
  created_at: string
}

export function MonthlyLossReport() {
  const [losses, setLosses] = useState<MonthlyLoss[]>([])
  const [loading, setLoading] = useState(true)
  const supabase = createClient()

  useEffect(() => {
    fetchMonthlyLosses()
  }, [])

  const fetchMonthlyLosses = async () => {
    try {
      const { data, error } = await supabase
        .from("monthly_losses")
        .select("*")
        .order("year", { ascending: false })
        .order("month", { ascending: false })

      if (error) throw error
      setLosses(data || [])
    } catch (error) {
      console.error("获取月度亏损数据失败:", error)
    } finally {
      setLoading(false)
    }
  }

  const getMonthName = (month: number) => {
    const months = ["一月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "十一月", "十二月"]
    return months[month - 1]
  }

  const totalLoss = losses.reduce((sum, loss) => sum + loss.total_loss_amount, 0)
  const totalBadDebts = losses.reduce((sum, loss) => sum + loss.bad_debt_count, 0)

  if (loading) {
    return (
      <Card>
        <CardContent className="p-8">
          <div className="flex items-center justify-center">
            <div className="text-muted-foreground">加载中...</div>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-6">
      {/* 统计概览 */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <DollarSign className="w-8 h-8 text-red-500" />
              <div>
                <div className="text-2xl font-bold text-red-600">RM {totalLoss.toLocaleString()}</div>
                <div className="text-sm text-muted-foreground">总亏损金额</div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <Users className="w-8 h-8 text-orange-500" />
              <div>
                <div className="text-2xl font-bold text-orange-600">{totalBadDebts}</div>
                <div className="text-sm text-muted-foreground">烂账客户数</div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <TrendingDown className="w-8 h-8 text-gray-500" />
              <div>
                <div className="text-2xl font-bold text-gray-600">
                  {totalBadDebts > 0 ? `RM ${(totalLoss / totalBadDebts).toLocaleString()}` : "RM 0"}
                </div>
                <div className="text-sm text-muted-foreground">平均亏损</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 月度明细 */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="flex items-center space-x-2">
            <Calendar className="w-5 h-5" />
            <span>月度亏损明细</span>
          </CardTitle>
          <Button variant="outline" size="sm" onClick={fetchMonthlyLosses}>
            刷新数据
          </Button>
        </CardHeader>
        <CardContent>
          {losses.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">暂无亏损记录</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-border">
                    <th className="text-left py-3 px-4 font-medium text-muted-foreground">年月</th>
                    <th className="text-left py-3 px-4 font-medium text-muted-foreground">亏损金额</th>
                    <th className="text-left py-3 px-4 font-medium text-muted-foreground">烂账数量</th>
                    <th className="text-left py-3 px-4 font-medium text-muted-foreground">平均亏损</th>
                  </tr>
                </thead>
                <tbody>
                  {losses.map((loss) => (
                    <tr key={loss.id} className="border-b border-border hover:bg-muted/50">
                      <td className="py-3 px-4 font-medium">
                        {loss.year}年 {getMonthName(loss.month)}
                      </td>
                      <td className="py-3 px-4 text-red-600 font-medium">
                        RM {loss.total_loss_amount.toLocaleString()}
                      </td>
                      <td className="py-3 px-4">{loss.bad_debt_count}</td>
                      <td className="py-3 px-4">
                        RM {(loss.total_loss_amount / loss.bad_debt_count).toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
