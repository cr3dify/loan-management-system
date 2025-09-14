-- 修复 RLS 策略配置
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 首先检查当前策略
SELECT policyname, cmd, roles, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'customers';

-- 2. 删除现有的客户表策略（如果存在）
DROP POLICY IF EXISTS "Users can view all customers" ON public.customers;
DROP POLICY IF EXISTS "Users can insert customers" ON public.customers;
DROP POLICY IF EXISTS "Users can update customers" ON public.customers;
DROP POLICY IF EXISTS "Users can delete customers" ON public.customers;

-- 3. 创建更宽松的 RLS 策略
-- 允许所有认证用户访问客户表
CREATE POLICY "Authenticated users can view customers" 
ON public.customers FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "Authenticated users can insert customers" 
ON public.customers FOR INSERT 
TO authenticated 
WITH CHECK (true);

CREATE POLICY "Authenticated users can update customers" 
ON public.customers FOR UPDATE 
TO authenticated 
USING (true);

CREATE POLICY "Authenticated users can delete customers" 
ON public.customers FOR DELETE 
TO authenticated 
USING (true);

-- 4. 如果上面的策略还是太严格，可以临时禁用 RLS（仅用于测试）
-- 注意：生产环境中不建议这样做
-- ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;

-- 5. 验证策略是否生效
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'customers'
ORDER BY policyname;
