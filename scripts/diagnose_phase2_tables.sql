-- =========================================================================
-- Phase 2 数据库表诊断脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 检查 Phase 2 表是否存在
SELECT 
  table_name,
  table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('expense_types', 'expenses', 'employee_profits', 'approval_records')
ORDER BY table_name;

-- 2. 检查费用类型表结构和数据
SELECT 'expense_types 表结构:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'expense_types' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'expense_types 数据:' as info;
SELECT * FROM public.expense_types LIMIT 5;

-- 3. 检查费用表结构
SELECT 'expenses 表结构:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'expenses' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. 检查 RLS 策略
SELECT 'expenses 表 RLS 策略:' as info;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'expenses' 
  AND schemaname = 'public';

-- 5. 检查用户表是否存在（用于外键关联）
SELECT 'users 表结构:' as info;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'public'
  AND column_name IN ('id', 'full_name', 'username')
ORDER BY ordinal_position;

-- 6. 测试基本查询
SELECT '测试基本查询:' as info;
SELECT COUNT(*) as expense_count FROM public.expenses;
SELECT COUNT(*) as expense_type_count FROM public.expense_types;
