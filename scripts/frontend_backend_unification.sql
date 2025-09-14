-- =========================================================================
-- 前端后端数据结构统一优化脚本
-- 基于一致性分析报告的修复方案
-- =========================================================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================================================================
-- 第一部分：修复 customers 表结构
-- =========================================================================

-- 1. 移除不需要的字段（与前端类型不匹配）
ALTER TABLE public.customers DROP COLUMN IF EXISTS name;
ALTER TABLE public.customers DROP COLUMN IF EXISTS id_card;

-- 2. 添加前端需要但数据库缺失的字段
ALTER TABLE public.customers 
ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;

-- 3. 确保所有必需字段存在且类型正确
ALTER TABLE public.customers 
ALTER COLUMN customer_number DROP NOT NULL; -- 设为可选

-- =========================================================================
-- 第二部分：优化 loans 表结构
-- =========================================================================

-- 重新创建 loans 表，移除重复字段，只保留贷款相关的核心字段
DROP TABLE IF EXISTS public.loans CASCADE;

CREATE TABLE public.loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    loan_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    deposit_amount DECIMAL(15,2) NOT NULL,
    cycle_days INTEGER NOT NULL DEFAULT 30,
    loan_method VARCHAR(20) NOT NULL DEFAULT 'scenario_a' CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c')),
    disbursement_date DATE NOT NULL,
    actual_amount DECIMAL(15,2) NOT NULL, -- 实际放款金额
    remaining_principal DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'overdue', 'bad_debt')),
    issue_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =========================================================================
-- 第三部分：修复 repayments 表字段名
-- =========================================================================

-- 统一字段名：repayment_date -> payment_date
ALTER TABLE public.repayments 
RENAME COLUMN repayment_date TO payment_date;

-- 添加缺失的字段
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS processed_by UUID REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- =========================================================================
-- 第四部分：创建或更新触发器
-- =========================================================================

-- 自动更新 updated_at 字段的函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为相关表添加触发器
DROP TRIGGER IF EXISTS update_customers_updated_at ON public.customers;
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON public.customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_loans_updated_at ON public.loans;
CREATE TRIGGER update_loans_updated_at
    BEFORE UPDATE ON public.loans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =========================================================================
-- 第五部分：重新创建索引
-- =========================================================================

-- 删除旧索引
DROP INDEX IF EXISTS idx_loans_customer_id;
DROP INDEX IF EXISTS idx_loans_status;
DROP INDEX IF EXISTS idx_repayments_customer_id;
DROP INDEX IF EXISTS idx_repayments_payment_date;
DROP INDEX IF EXISTS idx_repayments_loan_id;

-- 创建优化的索引
CREATE INDEX idx_customers_status ON public.customers(status);
CREATE INDEX idx_customers_created_at ON public.customers(created_at);
CREATE INDEX idx_customers_customer_code ON public.customers(customer_code);
CREATE INDEX idx_customers_assigned_to ON public.customers(assigned_to);

CREATE INDEX idx_loans_customer_id ON public.loans(customer_id);
CREATE INDEX idx_loans_status ON public.loans(status);
CREATE INDEX idx_loans_disbursement_date ON public.loans(disbursement_date);

CREATE INDEX idx_repayments_customer_id ON public.repayments(customer_id);
CREATE INDEX idx_repayments_payment_date ON public.repayments(payment_date);
CREATE INDEX idx_repayments_loan_id ON public.repayments(loan_id);

-- =========================================================================
-- 第六部分：更新 RLS 策略
-- =========================================================================

-- 重新创建 loans 表的 RLS 策略
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to read loans" ON public.loans;
CREATE POLICY "Allow authenticated users to read loans" ON public.loans
    FOR ALL USING (auth.role() = 'authenticated');

-- =========================================================================
-- 第七部分：数据迁移和清理
-- =========================================================================

-- 如果存在旧数据，需要手动迁移到新的 loans 表结构
-- 这里提供迁移模板，需要根据实际数据情况调整

/*
-- 示例：从 customers 表迁移贷款数据到 loans 表
INSERT INTO public.loans (
    customer_id,
    loan_amount,
    interest_rate,
    deposit_amount,
    cycle_days,
    loan_method,
    disbursement_date,
    actual_amount,
    remaining_principal,
    status
)
SELECT 
    id as customer_id,
    loan_amount,
    interest_rate,
    deposit_amount,
    30 as cycle_days, -- 默认30天
    loan_method,
    CURRENT_DATE as disbursement_date,
    received_amount as actual_amount,
    loan_amount as remaining_principal, -- 初始剩余本金等于贷款金额
    'active' as status
FROM public.customers 
WHERE loan_amount > 0;
*/

-- =========================================================================
-- 完成提示
-- =========================================================================

SELECT 
    'Frontend-Backend unification completed!' as message,
    'Tables structure now matches TypeScript interfaces' as status,
    'Please update frontend types if needed' as next_step;

-- =========================================================================
-- 验证脚本
-- =========================================================================

-- 验证表结构
\d+ public.customers;
\d+ public.loans;
\d+ public.repayments;

-- 验证约束
SELECT 
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'public' 
AND table_name IN ('customers', 'loans', 'repayments')
ORDER BY table_name, constraint_type;