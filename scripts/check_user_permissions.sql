-- =========================================================================
-- 检查当前用户权限脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 检查当前认证用户
SELECT '当前认证用户信息:' as info;
SELECT 
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NULL THEN '未登录'
        ELSE '已登录'
    END as login_status;

-- 2. 检查用户表中的当前用户
SELECT '用户表中的当前用户:' as info;
SELECT 
    id,
    username,
    full_name,
    role,
    email,
    is_active
FROM public.users 
WHERE id = auth.uid();

-- 3. 测试费用表访问权限
SELECT '费用表访问测试:' as info;
SELECT COUNT(*) as total_expenses FROM public.expenses;

-- 4. 测试费用类型表访问权限
SELECT '费用类型表访问测试:' as info;
SELECT COUNT(*) as total_expense_types FROM public.expense_types;

-- 5. 检查 RLS 策略
SELECT 'expenses 表 RLS 策略:' as info;
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'expenses' 
  AND schemaname = 'public';

-- 6. 测试具体查询（模拟前端查询）
SELECT '模拟前端查询测试:' as info;
SELECT 
    e.id,
    e.amount,
    e.description,
    e.approval_status,
    et.name as expense_type_name,
    u.full_name as employee_name
FROM public.expenses e
LEFT JOIN public.expense_types et ON e.expense_type_id = et.id
LEFT JOIN public.users u ON e.employee_id = u.id
LIMIT 5;