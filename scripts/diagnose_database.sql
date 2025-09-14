-- =========================================================================
-- 数据库诊断脚本
-- 检查当前数据库中的表结构和字段
-- =========================================================================

-- 1. 检查所有表是否存在
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('customers', 'loans', 'repayments', 'overdue_records', 'system_settings', 'contract_templates', 'monthly_losses')
ORDER BY table_name;

-- 2. 检查 repayments 表的字段结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. 检查 customers 表的字段结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'customers' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. 检查是否有数据
SELECT 
    'customers' as table_name,
    COUNT(*) as row_count
FROM public.customers
UNION ALL
SELECT 
    'repayments' as table_name,
    COUNT(*) as row_count
FROM public.repayments;

-- 5. 检查策略是否存在
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('customers', 'repayments')
ORDER BY tablename, policyname;