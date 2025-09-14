-- 修复用户访问权限
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 首先检查当前策略
SELECT 
    'Current policies:' as info,
    policyname,
    cmd,
    roles,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'customers';

-- 2. 删除所有现有的客户表策略
DROP POLICY IF EXISTS "Users can view all customers" ON public.customers;
DROP POLICY IF EXISTS "Users can insert customers" ON public.customers;
DROP POLICY IF EXISTS "Users can update customers" ON public.customers;
DROP POLICY IF EXISTS "Users can delete customers" ON public.customers;
DROP POLICY IF EXISTS "Authenticated users can view customers" ON public.customers;
DROP POLICY IF EXISTS "Authenticated users can insert customers" ON public.customers;
DROP POLICY IF EXISTS "Authenticated users can update customers" ON public.customers;
DROP POLICY IF EXISTS "Authenticated users can delete customers" ON public.customers;

-- 3. 创建新的宽松策略（允许所有认证用户访问）
CREATE POLICY "Allow all for authenticated users" 
ON public.customers 
FOR ALL 
TO authenticated 
USING (true)
WITH CHECK (true);

-- 4. 验证新策略
SELECT 
    'New policies:' as info,
    policyname,
    cmd,
    roles,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'customers';

-- 5. 测试访问权限
SELECT 
    'Access test:' as info,
    COUNT(*) as customer_count
FROM public.customers;

-- 6. 如果上面的策略还是有问题，可以临时禁用 RLS（仅用于测试）
-- 注意：生产环境中不建议这样做
-- ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;

-- 7. 重新启用 RLS（如果需要）
-- ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
