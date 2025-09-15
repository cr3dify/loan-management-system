-- 临时测试脚本，检查数据库连接
-- 在 Supabase SQL Editor 中执行，验证数据库是否正常

-- 1. 检查 repayments 表是否存在
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'repayments'
) as table_exists;

-- 2. 检查 repayments 表结构
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. 检查是否有 remaining_principal 字段
SELECT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_name = 'repayments' 
        AND column_name = 'remaining_principal' 
        AND table_schema = 'public'
) as remaining_principal_exists;

-- 4. 如果字段不存在，添加它
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'repayments' 
            AND column_name = 'remaining_principal' 
            AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.repayments 
        ADD COLUMN remaining_principal DECIMAL(15,2) DEFAULT 0;
        RAISE NOTICE '✅ remaining_principal 字段已添加';
    ELSE
        RAISE NOTICE 'ℹ️  remaining_principal 字段已存在';
    END IF;
END $$;

SELECT '数据库连接测试完成' as status;