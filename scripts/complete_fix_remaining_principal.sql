-- =========================================================================
-- 彻底修复 remaining_principal 字段问题
-- 请在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 启用 UUID 扩展（如果需要）
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. 检查并添加 remaining_principal 字段
DO $$
BEGIN
    -- 检查字段是否存在
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'repayments' 
            AND column_name = 'remaining_principal' 
            AND table_schema = 'public'
    ) THEN
        -- 添加字段
        ALTER TABLE public.repayments 
        ADD COLUMN remaining_principal DECIMAL(15,2) DEFAULT 0;
        
        RAISE NOTICE '✅ remaining_principal 字段已成功添加';
    ELSE
        RAISE NOTICE 'ℹ️  remaining_principal 字段已存在';
    END IF;
END $$;

-- 3. 确保其他必要字段也存在
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) DEFAULT 'cash' 
    CHECK (payment_method IN ('cash', 'bank_transfer', 'check', 'other'));

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS receipt_number VARCHAR(100);

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS processed_by UUID REFERENCES auth.users(id);

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 4. 验证表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. 测试插入（确保字段可用）
DO $$
BEGIN
    BEGIN
        -- 测试插入
        INSERT INTO public.repayments (
            customer_id,
            amount,
            payment_date,
            due_date,
            repayment_type,
            remaining_principal
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            100,
            CURRENT_DATE,
            CURRENT_DATE,
            'partial_principal',
            500
        );
        
        -- 立即删除测试数据
        DELETE FROM public.repayments 
        WHERE customer_id = '00000000-0000-0000-0000-000000000000';
        
        RAISE NOTICE '✅ 字段测试成功！remaining_principal 可以正常使用';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 字段测试失败: %', SQLERRM;
    END;
END $$;

SELECT '🎉 数据库修复完成！' as final_status;