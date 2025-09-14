-- 检查用户权限和 RLS 策略
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 检查当前用户信息
SELECT 
    auth.uid() as current_user_id,
    auth.role() as current_role,
    auth.email() as current_email;

-- 2. 检查客户表的 RLS 状态
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'customers';

-- 3. 检查客户表的 RLS 策略
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'customers'
ORDER BY policyname;

-- 4. 测试客户表访问权限
SELECT COUNT(*) as total_customers FROM public.customers;

-- 5. 检查用户是否有正确的角色
SELECT 
    id,
    email,
    raw_user_meta_data,
    raw_app_meta_data
FROM auth.users 
WHERE id = '8b080685-8daf-4d1f-8254-d83f1e9a911d';

-- 6. 测试插入权限（使用当前用户上下文）
-- 注意：这个查询需要在用户已登录的情况下执行
SELECT 
    'INSERT test' as test_type,
    CASE 
        WHEN has_table_privilege('public.customers', 'INSERT') THEN 'YES'
        ELSE 'NO'
    END as can_insert,
    CASE 
        WHEN has_table_privilege('public.customers', 'SELECT') THEN 'YES'
        ELSE 'NO'
    END as can_select,
    CASE 
        WHEN has_table_privilege('public.customers', 'UPDATE') THEN 'YES'
        ELSE 'NO'
    END as can_update;
