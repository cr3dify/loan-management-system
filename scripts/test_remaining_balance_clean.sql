-- =========================================================================
-- 剩余余额自动计算功能测试脚本（无模拟数据版本）
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 检查现有客户数据
SELECT 
  COUNT(*) as total_customers,
  COUNT(CASE WHEN remaining_balance > 0 THEN 1 END) as customers_with_balance,
  COUNT(CASE WHEN status = 'cleared' THEN 1 END) as cleared_customers
FROM public.customers;

-- 2. 检查函数是否存在
SELECT 
  proname as function_name,
  proargnames as argument_names,
  prorettype::regtype as return_type
FROM pg_proc 
WHERE proname = 'process_repayment';

-- 3. 检查触发器是否存在
SELECT 
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  tgenabled as enabled
FROM pg_trigger 
WHERE tgname = 'trigger_set_initial_remaining_balance';

-- 4. 检查约束是否存在
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.customers'::regclass 
AND conname LIKE '%loan_method%';

-- 5. 显示客户余额信息
SELECT 
  customer_code,
  full_name,
  loan_amount,
  remaining_balance,
  status,
  created_at
FROM public.customers 
ORDER BY created_at DESC 
LIMIT 10;

-- 6. 显示最近的还款记录
SELECT 
  r.id,
  c.full_name,
  r.amount,
  r.principal_amount,
  r.interest_amount,
  r.payment_date,
  r.repayment_type
FROM public.repayments r
JOIN public.customers c ON r.customer_id = c.id
ORDER BY r.payment_date DESC 
LIMIT 10;

SELECT '🎉 系统检查完成！' as status;

