-- =========================================================================
-- 贷款管理系统快速数据库初始化脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 客户表 (最简版本，包含Dashboard所需字段)
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_code VARCHAR(50) UNIQUE NOT NULL,
    customer_number VARCHAR(20) UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    id_number VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    notes TEXT,
    loan_amount DECIMAL(15,2) DEFAULT 0,
    interest_rate DECIMAL(5,2) DEFAULT 0,
    loan_method VARCHAR(20) DEFAULT 'scenario_a' CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c')),
    deposit_amount DECIMAL(15,2) DEFAULT 0,
    received_amount DECIMAL(15,2) DEFAULT 0,
    suggested_payment DECIMAL(15,2) DEFAULT 0,
    total_repayment DECIMAL(15,2) DEFAULT 0,
    periods INTEGER DEFAULT 0,
    principal_rate_per_period DECIMAL(5,2) DEFAULT 0,
    number_of_periods INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'normal' CHECK (status IN ('normal', 'overdue', 'cleared', 'negotiating', 'bad_debt')),
    approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    contract_signed BOOLEAN DEFAULT FALSE,
    contract_signed_at TIMESTAMP WITH TIME ZONE,
    negotiation_terms TEXT,
    loss_amount DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 贷款表 (简化版)
CREATE TABLE IF NOT EXISTS public.loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    loan_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    deposit_amount DECIMAL(15,2) NOT NULL,
    cycle_days INTEGER NOT NULL,
    loan_method VARCHAR(20) NOT NULL DEFAULT 'scenario_a' CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c')),
    disbursement_date DATE NOT NULL,
    actual_amount DECIMAL(15,2) NOT NULL,
    remaining_principal DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'overdue', 'bad_debt')),
    issue_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 还款记录表 (包含Dashboard所需的客户关联)
CREATE TABLE IF NOT EXISTS public.repayments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID REFERENCES public.loans(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    repayment_type VARCHAR(20) NOT NULL CHECK (repayment_type IN ('interest_only', 'partial_principal', 'full_settlement')),
    amount DECIMAL(15,2) NOT NULL,
    interest_amount DECIMAL(15,2) DEFAULT 0,
    principal_amount DECIMAL(15,2) DEFAULT 0,
    penalty_amount DECIMAL(15,2) DEFAULT 0,
    excess_amount DECIMAL(15,2) DEFAULT 0,
    remaining_principal DECIMAL(15,2) DEFAULT 0,
    payment_date DATE NOT NULL,
    due_date DATE NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'cash' CHECK (payment_method IN ('cash', 'bank_transfer', 'check', 'other')),
    receipt_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 系统设置表 (简化版)
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type VARCHAR(20) DEFAULT 'string' CHECK (setting_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =========================================================================
-- 第二部分：初始化完成
-- =========================================================================

-- =========================================================================
-- 第三部分：行级安全策略 (RLS)
-- =========================================================================

-- 启用行级安全
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repayments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- 创建基本的策略 (允许认证用户访问所有数据)
CREATE POLICY "Allow authenticated users to read customers" ON public.customers
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to read loans" ON public.loans
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to read repayments" ON public.repayments
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated users to read system_settings" ON public.system_settings
    FOR ALL USING (auth.role() = 'authenticated');

-- =========================================================================
-- 第四部分：索引优化
-- =========================================================================

-- 创建必要的索引
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON public.customers(created_at);
CREATE INDEX IF NOT EXISTS idx_customers_customer_code ON public.customers(customer_code);

CREATE INDEX IF NOT EXISTS idx_loans_customer_id ON public.loans(customer_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON public.loans(status);

CREATE INDEX IF NOT EXISTS idx_repayments_customer_id ON public.repayments(customer_id);
CREATE INDEX IF NOT EXISTS idx_repayments_payment_date ON public.repayments(payment_date);
CREATE INDEX IF NOT EXISTS idx_repayments_loan_id ON public.repayments(loan_id);

-- =========================================================================
-- 完成提示
-- =========================================================================

SELECT 
    'Database tables created successfully!' as message,
    'Ready for data entry' as status;