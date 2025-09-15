-- =========================================================================
-- 终极解决方案：重建 repayments 表
-- 如果上面的修复还是不行，请执行这个脚本
-- =========================================================================

-- 1. 删除现有的 repayments 表（包含所有约束和索引）
DROP TABLE IF EXISTS public.repayments CASCADE;

-- 2. 重新创建一个最简单的 repayments 表
CREATE TABLE public.repayments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL,
    loan_id UUID,
    amount DECIMAL(15,2) NOT NULL,
    principal_amount DECIMAL(15,2) DEFAULT 0,
    interest_amount DECIMAL(15,2) DEFAULT 0,
    penalty_amount DECIMAL(15,2) DEFAULT 0,
    excess_amount DECIMAL(15,2) DEFAULT 0,
    repayment_type VARCHAR(20) NOT NULL DEFAULT 'partial_principal',
    payment_date DATE NOT NULL,
    due_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 创建基本索引
CREATE INDEX idx_repayments_customer_id ON public.repayments(customer_id);
CREATE INDEX idx_repayments_payment_date ON public.repayments(payment_date);

-- 4. 启用行级安全（如果需要）
ALTER TABLE public.repayments ENABLE ROW LEVEL SECURITY;

-- 5. 创建策略
CREATE POLICY "Allow all operations for authenticated users" ON public.repayments
    FOR ALL USING (auth.role() = 'authenticated');

-- 6. 验证表结构
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '🎉 全新 repayments 表创建完成！' as final_result;