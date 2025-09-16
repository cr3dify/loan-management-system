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
  remaining_balance: number // 剩余余额字段
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
  // remaining_principal?: number // 临时移除这个字段
  payment_date: string // 统一字段名：payment_date
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
  name: string
  email: string
  role: "admin" | "secretary" | "employee"
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

export interface ExpenseType {
  id: string
  name: string
  description?: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Expense {
  id: string
  employee_id: string
  expense_type_id: string
  amount: number
  description: string
  expense_date: string
  receipt_url?: string
  approval_status: "pending" | "approved" | "rejected"
  approved_by?: string
  approved_at?: string
  rejection_reason?: string
  created_at: string
  updated_at: string
  expense_type?: ExpenseType
  employee?: User
  approver?: User
}

export interface EmployeeProfit {
  id: string
  employee_id: string
  period_year: number
  period_month: number
  total_loans: number
  total_repayments: number
  total_expenses: number
  net_profit: number
  roi_percentage: number
  created_at: string
  updated_at: string
  employee?: User
}

export interface ApprovalRecord {
  id: string
  record_type: "customer" | "expense" | "repayment"
  record_id: string
  approver_id: string
  approval_status: "pending" | "approved" | "rejected"
  approval_level: number
  comments?: string
  approved_at: string
  created_at: string
  approver?: User
}
