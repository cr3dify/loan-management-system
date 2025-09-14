-- 修复客户状态约束问题
-- 在 Supabase SQL Editor 中执行此脚本

-- 1. 检查当前约束
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.customers'::regclass 
AND contype = 'c'
AND conname LIKE '%status%';

-- 2. 删除旧的状态约束
ALTER TABLE public.customers DROP CONSTRAINT IF EXISTS customers_status_check;

-- 3. 添加新的状态约束（包含所有可能的状态）
ALTER TABLE public.customers 
ADD CONSTRAINT customers_status_check 
CHECK (status IN ('normal', 'cleared', 'negotiating', 'bad_debt', 'overdue'));

-- 4. 验证约束已正确创建
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.customers'::regclass 
AND contype = 'c'
AND conname = 'customers_status_check';

-- 5. 测试状态更新（可选）
-- UPDATE customers SET status = 'cleared' WHERE id = (SELECT id FROM customers LIMIT 1);

SELECT '✅ 客户状态约束修复完成！现在可以使用所有状态：normal, cleared, negotiating, bad_debt, overdue' as result;