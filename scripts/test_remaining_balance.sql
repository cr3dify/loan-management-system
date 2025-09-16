-- =========================================================================
-- 测试剩余余额自动计算功能
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 创建测试客户
INSERT INTO public.customers (
  customer_code, 
  full_name, 
  id_number, 
  phone, 
  address, 
  loan_amount,
  interest_rate,
  loan_method,  -- 添加正确的贷款方式
  status
) VALUES (
  'TEST001', 
  '测试客户张三', 
  '123456789', 
  '0123456789', 
  '测试地址123', 
  10000,        -- 借款1万
  10,           -- 10%利息
  'scenario_a', -- 正确的贷款方式
  'normal'
) RETURNING id, customer_code, loan_amount, remaining_balance;

-- 2. 获取测试客户ID
DO $$
DECLARE
  test_customer_id uuid;
  test_result record;
  current_balance numeric;
BEGIN
  -- 获取测试客户ID
  SELECT id INTO test_customer_id 
  FROM public.customers 
  WHERE customer_code = 'TEST001';
  
  IF test_customer_id IS NULL THEN
    RAISE NOTICE '❌ 测试客户创建失败';
    RETURN;
  END IF;
  
  RAISE NOTICE '✅ 测试客户创建成功，ID: %', test_customer_id;
  
  -- 查看初始余额
  SELECT remaining_balance INTO current_balance 
  FROM public.customers 
  WHERE id = test_customer_id;
  
  RAISE NOTICE '💰 初始余额: RM %', current_balance;
  
  -- 测试还款 1000（部分本金）
  RAISE NOTICE '🔄 测试还款 RM 1000...';
  
  SELECT * INTO test_result FROM public.process_repayment(
    test_customer_id,      -- 客户ID
    test_customer_id,      -- 贷款ID
    1000,                  -- 还款金额
    1000,                  -- 本金
    0,                     -- 利息
    0,                     -- 罚金
    0,                     -- 多余
    'partial_principal',   -- 还款类型
    CURRENT_DATE,          -- 还款日期
    '测试还款1000'         -- 备注
  );
  
  -- 检查结果
  IF test_result.success THEN
    RAISE NOTICE '✅ 第一次还款成功！';
    RAISE NOTICE '💰 剩余余额: RM %', test_result.new_remaining_balance;
  ELSE
    RAISE NOTICE '❌ 第一次还款失败: %', test_result.message;
  END IF;
  
  -- 测试还款 500（部分本金）
  RAISE NOTICE '🔄 测试还款 RM 500...';
  
  SELECT * INTO test_result FROM public.process_repayment(
    test_customer_id,
    test_customer_id,
    500,
    500,  -- 本金
    0,    -- 利息
    0,    -- 罚金
    0,    -- 多余
    'partial_principal',
    CURRENT_DATE,
    '测试还款500'
  );
  
  -- 检查结果
  IF test_result.success THEN
    RAISE NOTICE '✅ 第二次还款成功！';
    RAISE NOTICE '💰 剩余余额: RM %', test_result.new_remaining_balance;
  ELSE
    RAISE NOTICE '❌ 第二次还款失败: %', test_result.message;
  END IF;
  
  -- 测试全额结清
  RAISE NOTICE '🔄 测试全额结清...';
  
  SELECT * INTO test_result FROM public.process_repayment(
    test_customer_id,
    test_customer_id,
    8500,  -- 剩余金额
    8500,  -- 本金
    0,     -- 利息
    0,     -- 罚金
    0,     -- 多余
    'full_settlement',
    CURRENT_DATE,
    '全额结清'
  );
  
  -- 检查结果
  IF test_result.success THEN
    RAISE NOTICE '✅ 全额结清成功！';
    RAISE NOTICE '💰 剩余余额: RM %', test_result.new_remaining_balance;
    
    -- 检查客户状态
    SELECT status INTO current_balance 
    FROM public.customers 
    WHERE id = test_customer_id;
    
    RAISE NOTICE '📊 客户状态: %', current_balance;
  ELSE
    RAISE NOTICE '❌ 全额结清失败: %', test_result.message;
  END IF;
  
  -- 清理测试数据
  DELETE FROM public.repayments WHERE customer_id = test_customer_id;
  DELETE FROM public.customers WHERE id = test_customer_id;
  
  RAISE NOTICE '🧹 测试数据已清理';
  
END $$;

-- 3. 显示测试结果
SELECT '🎉 剩余余额自动计算功能测试完成！' as status;
