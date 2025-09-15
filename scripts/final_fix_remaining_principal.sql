-- =========================================================================
-- 最终修复脚本：解决 remaining_principal 字段问题
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 检查当前 repayments 表结构
DO $$
BEGIN
    RAISE NOTICE '正在检查 repayments 表结构...';
END $$;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. 添加 remaining_principal 字段（如果不存在）
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
        
        RAISE NOTICE '✅ remaining_principal 字段已添加';
    ELSE
        RAISE NOTICE 'ℹ️  remaining_principal 字段已存在';
    END IF;
END $$;

-- 3. 确保其他可能缺失的字段也存在
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) DEFAULT 'cash' 
    CHECK (payment_method IN ('cash', 'bank_transfer', 'check', 'other'));

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS receipt_number VARCHAR(100);

-- 4. 验证修复结果
SELECT 
    '✅ 字段修复验证' as status,
    column_name
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND column_name IN ('remaining_principal', 'payment_method', 'receipt_number')
    AND table_schema = 'public';

-- 5. 测试插入（会立即回滚，不影响数据）
DO $$
BEGIN
    -- 测试插入
    BEGIN
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
        
        RAISE NOTICE '✅ 插入测试成功！remaining_principal 字段可以正常使用';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 插入测试失败: %', SQLERRM;
    END;
END $$;

SELECT '🎉 修复脚本执行完成！' as final_status;