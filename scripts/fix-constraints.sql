-- 修复客户表的状态约束
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 检查当前约束
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.customers'::regclass 
AND contype = 'c';

-- 2. 删除旧的状态约束
ALTER TABLE public.customers DROP CONSTRAINT IF EXISTS customers_status_check;

-- 3. 添加新的状态约束（包含所有可能的状态）
ALTER TABLE public.customers 
ADD CONSTRAINT customers_status_check 
CHECK (status IN ('normal', 'cleared', 'negotiating', 'bad_debt', 'overdue'));

-- 4. 删除旧的审核状态约束
ALTER TABLE public.customers DROP CONSTRAINT IF EXISTS customers_approval_status_check;

-- 5. 添加新的审核状态约束
ALTER TABLE public.customers 
ADD CONSTRAINT customers_approval_status_check 
CHECK (approval_status IN ('pending', 'approved', 'rejected'));

-- 6. 验证约束
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.customers'::regclass 
AND contype = 'c';

