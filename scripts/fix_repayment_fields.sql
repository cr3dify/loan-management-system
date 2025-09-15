-- =========================================================================
-- 修复还款功能的字段名一致性问题
-- 将 repayment_date 字段统一为 payment_date
-- =========================================================================

-- 启用 UUID 扩展（如果未启用）
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 检查当前 repayments 表的字段结构
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. 如果存在 repayment_date 字段，重命名为 payment_date
DO $$
BEGIN
    -- 检查是否存在 repayment_date 字段
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repayments' 
            AND column_name = 'repayment_date' 
            AND table_schema = 'public'
    ) THEN
        -- 重命名字段
        ALTER TABLE public.repayments RENAME COLUMN repayment_date TO payment_date;
        RAISE NOTICE '✅ repayment_date 字段已重命名为 payment_date';
    ELSE
        RAISE NOTICE 'ℹ️  repayment_date 字段不存在，可能已经是 payment_date';
    END IF;
END $$;

-- 3. 确保表结构完整
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) DEFAULT 'cash' 
    CHECK (payment_method IN ('cash', 'bank_transfer', 'check', 'other'));

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS receipt_number VARCHAR(100);

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS processed_by UUID REFERENCES auth.users(id);

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 添加 remaining_principal 字段（如果不存在）
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS remaining_principal DECIMAL(15,2) DEFAULT 0;

-- 4. 更新 RLS 策略
ALTER TABLE public.repayments ENABLE ROW LEVEL SECURITY;

-- 删除旧策略（如果存在）
DROP POLICY IF EXISTS "Allow authenticated users to access repayments" ON public.repayments;

-- 创建新策略
CREATE POLICY "Allow authenticated users to access repayments" ON public.repayments
    FOR ALL USING (auth.role() = 'authenticated');

-- 5. 创建或更新索引
CREATE INDEX IF NOT EXISTS idx_repayments_customer_id ON public.repayments(customer_id);
CREATE INDEX IF NOT EXISTS idx_repayments_payment_date ON public.repayments(payment_date);
CREATE INDEX IF NOT EXISTS idx_repayments_loan_id ON public.repayments(loan_id);

-- 6. 验证修复结果
SELECT 'repayments 表字段修复完成！' as message;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;