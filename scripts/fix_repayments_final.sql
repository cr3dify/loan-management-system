-- =========================================================================
-- 最终修复还款表结构脚本 (修复版)
-- 确保数据库表结构与前端代码完全一致
-- =========================================================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 备份现有数据（如果表存在）
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'repayments') THEN
        -- 创建备份表
        DROP TABLE IF EXISTS repayments_backup;
        CREATE TABLE repayments_backup AS SELECT * FROM repayments;
        RAISE NOTICE '已备份现有还款数据到 repayments_backup 表';
    END IF;
END $$;

-- 删除现有表
DROP TABLE IF EXISTS public.repayments CASCADE;

-- 重新创建还款记录表（与前端代码完全匹配）
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
    -- 注意：移除了 remaining_principal 字段，因为前端不使用
    repayment_date DATE NOT NULL, -- 前端使用 payment_date，但数据库保持 repayment_date
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

-- 如果有备份数据，尝试恢复（动态处理字段映射）
DO $$
DECLARE
    backup_exists BOOLEAN := FALSE;
    has_payment_date BOOLEAN := FALSE;
    restore_sql TEXT;
BEGIN
    -- 检查备份表是否存在
    SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'repayments_backup') INTO backup_exists;
    
    IF backup_exists THEN
        -- 检查备份表是否有 payment_date 字段（而不是 repayment_date）
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'repayments_backup' AND column_name = 'payment_date'
        ) INTO has_payment_date;
        
        -- 根据字段存在情况构建恢复SQL
        IF has_payment_date THEN
            -- 如果备份表使用 payment_date，映射到新表的 repayment_date
            restore_sql := '
                INSERT INTO public.repayments (
                    id, loan_id, customer_id, repayment_type, amount,
                    interest_amount, principal_amount, penalty_amount, excess_amount,
                    repayment_date, due_date, payment_method, receipt_number, notes, created_at
                )
                SELECT 
                    id, loan_id, customer_id, repayment_type, amount,
                    COALESCE(interest_amount, 0), COALESCE(principal_amount, 0), 
                    COALESCE(penalty_amount, 0), COALESCE(excess_amount, 0),
                    payment_date, due_date, 
                    COALESCE(payment_method, ''cash''), receipt_number, notes, created_at
                FROM repayments_backup';
        ELSE
            -- 如果备份表使用 repayment_date
            restore_sql := '
                INSERT INTO public.repayments (
                    id, loan_id, customer_id, repayment_type, amount,
                    interest_amount, principal_amount, penalty_amount, excess_amount,
                    repayment_date, due_date, payment_method, receipt_number, notes, created_at
                )
                SELECT 
                    id, loan_id, customer_id, repayment_type, amount,
                    COALESCE(interest_amount, 0), COALESCE(principal_amount, 0), 
                    COALESCE(penalty_amount, 0), COALESCE(excess_amount, 0),
                    repayment_date, due_date, 
                    COALESCE(payment_method, ''cash''), receipt_number, notes, created_at
                FROM repayments_backup';
        END IF;
        
        -- 执行恢复SQL
        EXECUTE restore_sql;
        
        RAISE NOTICE '已恢复还款数据（字段映射：% -> repayment_date）', 
            CASE WHEN has_payment_date THEN 'payment_date' ELSE 'repayment_date' END;
    ELSE
        RAISE NOTICE '没有找到备份数据，创建了空的还款表';
    END IF;
END $$;

-- 验证表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'repayments' 
ORDER BY ordinal_position;

-- 显示成功消息
SELECT '还款表结构已成功修复，与前端代码完全一致' as status;