import { createClient } from "@/lib/supabase/client"

export class StatusManager {
  private static supabase = createClient()

  /**
   * 自动更新客户状态
   */
  static async updateCustomerStatus(customerId: number): Promise<void> {
    try {
      // 获取客户信息和相关贷款记录
      const { data: customer, error: customerError } = await this.supabase
        .from("customers")
        .select("*")
        .eq("id", customerId)
        .single()

      if (customerError) throw customerError

      // 获取还款记录
      const { data: repayments, error: repaymentsError } = await this.supabase
        .from("repayments")
        .select("*")
        .eq("customer_id", customerId)
        .order("repayment_date", { ascending: false })

      if (repaymentsError) throw repaymentsError

      // 计算剩余本金
      const totalPrincipalPaid = repayments?.reduce((sum, r) => sum + (r.principal_amount || 0), 0) || 0
      const remainingPrincipal = customer.loan_amount - totalPrincipalPaid

      let newStatus = customer.status

      // 判断是否已结清
      if (remainingPrincipal <= 0) {
        newStatus = "cleared"
      } else {
        // 检查是否逾期（简化逻辑）
        const lastPayment = repayments?.[0]
        const daysSinceLastPayment = lastPayment
          ? Math.floor((Date.now() - new Date(lastPayment.repayment_date).getTime()) / (1000 * 60 * 60 * 24))
          : 0

        if (daysSinceLastPayment > 30) {
          // 超过30天未还款视为逾期
          newStatus = "overdue"
        } else if (customer.status === "overdue" && daysSinceLastPayment <= 7) {
          // 逾期后7天内还款恢复正常
          newStatus = "normal"
        }
      }

      // 更新客户状态
      if (newStatus !== customer.status) {
        const { error: updateError } = await this.supabase
          .from("customers")
          .update({ status: newStatus })
          .eq("id", customerId)

        if (updateError) throw updateError
      }
    } catch (error) {
      console.error("更新客户状态失败:", error)
    }
  }

  /**
   * 批量更新所有客户状态
   */
  static async updateAllCustomerStatuses(): Promise<void> {
    try {
      const { data: customers, error } = await this.supabase.from("customers").select("id").neq("status", "cleared")

      if (error) throw error

      // 并发更新所有客户状态
      const updatePromises = customers?.map((customer) => this.updateCustomerStatus(customer.id)) || []
      await Promise.all(updatePromises)
    } catch (error) {
      console.error("批量更新客户状态失败:", error)
    }
  }

  /**
   * 创建逾期记录
   */
  static async createOverdueRecord(customerId: number, loanId: number): Promise<void> {
    try {
      const overdueDays = 1 // 简化处理
      const penaltyRate = 5 // 5% 每天
      const { data: customer } = await this.supabase
        .from("customers")
        .select("loan_amount")
        .eq("id", customerId)
        .single()

      if (!customer) return

      const penaltyAmount = customer.loan_amount * (penaltyRate / 100) * overdueDays

      const { error } = await this.supabase.from("overdue_records").insert([
        {
          loan_id: loanId,
          customer_id: customerId,
          overdue_days: overdueDays,
          penalty_rate: penaltyRate,
          penalty_amount: penaltyAmount,
          overdue_date: new Date().toISOString().split("T")[0],
          status: "active",
        },
      ])

      if (error) throw error
    } catch (error) {
      console.error("创建逾期记录失败:", error)
    }
  }
}
