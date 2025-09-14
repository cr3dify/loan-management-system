-- 检查 RLS 策略配置
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 检查所有表的 RLS 状态
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- 2. 检查客户表的 RLS 策略
SELECT 
    schemaname,
    tablename,
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

-- 3. 检查当前用户信息
SELECT 
    auth.uid() as user_id,
    auth.role() as user_role,
    auth.email() as user_email;

-- 4. 测试客户表访问权限
-- 这个查询会显示是否有权限访问客户表
SELECT COUNT(*) as customer_count FROM public.customers;

-- 5. 检查认证状态
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';
