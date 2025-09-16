-- =========================================================================
-- 修复约束问题 - 快速解决 loan_method 约束错误
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 检查当前约束
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.customers'::regclass 
AND conname LIKE '%loan_method%';

-- 2. 如果存在旧的约束，先删除
ALTER TABLE public.customers 
DROP CONSTRAINT IF EXISTS check_loan_method;

ALTER TABLE public.customers 
DROP CONSTRAINT IF EXISTS check_customer_loan_method;

-- 3. 确保正确的约束存在
ALTER TABLE public.customers 
ADD CONSTRAINT customers_loan_method_check 
CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c'));

-- 4. 更新现有数据中的错误值
UPDATE public.customers 
SET loan_method = 'scenario_a'
WHERE loan_method NOT IN ('scenario_a', 'scenario_b', 'scenario_c')
OR loan_method IS NULL;

-- 5. 验证修复结果
SELECT 
  loan_method,
  COUNT(*) as count
FROM public.customers 
GROUP BY loan_method;

-- 6. 验证约束修复
DO $$
BEGIN
  -- 检查约束是否存在
  IF EXISTS (SELECT 1 FROM pg_constraint 
             WHERE conrelid = 'public.customers'::regclass 
             AND conname = 'customers_loan_method_check') THEN
    RAISE NOTICE '✅ loan_method 约束已正确设置';
  ELSE
    RAISE NOTICE '❌ loan_method 约束设置失败';
  END IF;
  
  -- 检查数据更新结果
  IF NOT EXISTS (SELECT 1 FROM public.customers 
                 WHERE loan_method NOT IN ('scenario_a', 'scenario_b', 'scenario_c')) THEN
    RAISE NOTICE '✅ 所有 loan_method 值已更新为正确格式';
  ELSE
    RAISE NOTICE '⚠️ 仍有部分 loan_method 值需要手动检查';
  END IF;
END $$;

SELECT '🎉 约束问题修复完成！' as status;
