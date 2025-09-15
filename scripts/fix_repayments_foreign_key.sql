-- =========================================================================
-- 修复 repayments 表外键关系
-- 解决 "Could not find a relationship between 'repayments' and 'customers'" 错误
-- =========================================================================

-- 1. 删除现有的 repayments 表
DROP TABLE IF EXISTS public.repayments CASCADE;

-- 2. 确保 customers 表存在且有正确结构
-- 这里只是验证，不会重复创建
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'customers' AND table_schema = 'public') THEN
        RAISE EXCEPTION 'customers 表不存在，请先创建 customers 表';
    END IF;
END $$;

-- 3. 重新创建 repayments 表，包含正确的外键关系
CREATE TABLE public.repayments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    loan_id UUID REFERENCES public.customers(id) ON DELETE CASCADE, -- 简化处理，指向客户
    amount DECIMAL(15,2) NOT NULL,
    principal_amount DECIMAL(15,2) DEFAULT 0,
    interest_amount DECIMAL(15,2) DEFAULT 0,
    penalty_amount DECIMAL(15,2) DEFAULT 0,
    excess_amount DECIMAL(15,2) DEFAULT 0,
    repayment_type VARCHAR(20) NOT NULL DEFAULT 'partial_principal' 
        CHECK (repayment_type IN ('interest_only', 'partial_principal', 'full_settlement')),
    payment_date DATE NOT NULL,
    due_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 创建索引优化查询性能
CREATE INDEX idx_repayments_customer_id ON public.repayments(customer_id);
CREATE INDEX idx_repayments_payment_date ON public.repayments(payment_date);
CREATE INDEX idx_repayments_repayment_type ON public.repayments(repayment_type);

-- 5. 启用行级安全
ALTER TABLE public.repayments ENABLE ROW LEVEL SECURITY;

-- 6. 删除可能存在的旧策略，然后创建新策略
DROP POLICY IF EXISTS "Allow all operations for authenticated users" ON public.repayments;
DROP POLICY IF EXISTS "Allow authenticated users to access repayments" ON public.repayments;

CREATE POLICY "Allow authenticated users to access repayments" ON public.repayments
    FOR ALL USING (auth.role() = 'authenticated');

-- 7. 验证外键关系是否正确创建
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'repayments'
    AND tc.table_schema = 'public';

-- 8. 验证表结构
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '🎉 repayments 表外键关系修复完成！' as status;