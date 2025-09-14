export interface Customer {
  id: string // UUID 字符串类型
  customer_code: string
  customer_number?: string // 可选字段
  full_name: string
  phone: string
  id_number: string
  address: string
  loan_amount: number
  interest_rate: number
  loan_method: "scenario_a" | "scenario_b" | "scenario_c"
  deposit_amount: number
  received_amount: number
  suggested_payment: number
  total_repayment: number
  periods: number
  principal_rate_per_period: number
  number_of_periods: number
  status: "normal" | "overdue" | "cleared" | "negotiating" | "bad_debt"
  notes?: string
  assigned_to?: string // UUID 字符串类型
  created_by?: string // UUID 字符串类型
  approval_status: "pending" | "approved" | "rejected"
  approved_by?: string // UUID 字符串类型
  approved_at?: string
  contract_signed: boolean
  contract_signed_at?: string
  negotiation_terms?: string
  loss_amount: number
  created_at: string
  updated_at: string
}

export interface Loan {
  id: string // UUID 字符串类型
  customer_id: string // UUID 字符串类型
  loan_amount: number
  interest_rate: number
  deposit_amount: number
  cycle_days: number // 添加数据库字段
  loan_method: "scenario_a" | "scenario_b" | "scenario_c"
  disbursement_date: string // 添加数据库字段
  actual_amount: number // 添加数据库字段
  remaining_principal: number
  status: "active" | "completed" | "overdue" | "bad_debt"
  issue_date: string
  due_date?: string
  notes?: string
  created_at: string
  updated_at: string
}

export interface Repayment {
  id: string // UUID 字符串类型
  loan_id: string // UUID 字符串类型
  customer_id: string // UUID 字符串类型
  amount: number
  principal_amount?: number
  interest_amount?: number
  penalty_amount?: number
  excess_amount?: number
  remaining_principal: number
  payment_date: string // 统一字段名：repayment_date -> payment_date
  due_date: string
  repayment_type: "interest_only" | "partial_principal" | "full_settlement"
  payment_method: "cash" | "bank_transfer" | "check" | "other"
  receipt_number?: string
  notes?: string
  processed_by?: string // UUID 字符串类型
  created_by?: string // UUID 字符串类型
  created_at: string
}

export interface OverdueRecord {
  id: string // 修改为 UUID 字符串类型
  loan_id: string // 修改为 UUID 字符串类型
  customer_id: string // 修改为 UUID 字符串类型
  overdue_days: number
  penalty_rate: number
  penalty_amount: number
  overdue_date: string
  resolved_date?: string
  status: "active" | "resolved" | "written_off"
  notes?: string
  created_at: string
  updated_at: string
}

export interface MonthlyLoss {
  id: string
  year: number
  month: number
  total_loss_amount: number
  bad_debt_count: number
  created_at: string
  updated_at: string
}

export interface ContractTemplate {
  id: string
  template_name: string
  template_content: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface User {
  id: string
  username: string
  full_name: string
  email: string
  role: "admin" | "secretary" | "manager"
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface SystemSetting {
  id: string
  setting_key: string
  setting_value: string
  setting_type: "string" | "number" | "boolean" | "json"
  description?: string
  created_at: string
  updated_at: string
}
