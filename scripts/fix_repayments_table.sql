-- =========================================================================
-- 修复还款表结构脚本
-- 确保还款表包含所有必需的字段
-- =========================================================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 删除可能存在的有问题的表
DROP TABLE IF EXISTS public.repayments CASCADE;

-- 重新创建还款记录表
CREATE TABLE public.repayments (
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
    repayment_date DATE NOT NULL,
    due_date DATE NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'cash' CHECK (payment_method IN ('cash', 'bank_transfer', 'check', 'other')),
    receipt_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 启用行级安全
ALTER TABLE public.repayments ENABLE ROW LEVEL SECURITY;

-- 创建策略
DROP POLICY IF EXISTS "Allow authenticated users to access repayments" ON public.repayments;
CREATE POLICY "Allow authenticated users to access repayments" ON public.repayments
    FOR ALL USING (auth.role() = 'authenticated');

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_repayments_customer_id ON public.repayments(customer_id);
CREATE INDEX IF NOT EXISTS idx_repayments_repayment_date ON public.repayments(repayment_date);
CREATE INDEX IF NOT EXISTS idx_repayments_loan_id ON public.repayments(loan_id);

-- 验证表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;