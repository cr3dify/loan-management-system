-- =========================================================================
-- RPC方案：统一还款处理函数
-- 解决 remaining_principal 字段问题的最佳实践
-- =========================================================================

-- 1. 创建还款处理函数
CREATE OR REPLACE FUNCTION public.process_repayment(
  p_customer_id uuid,
  p_loan_id uuid,
  p_amount numeric,
  p_principal_amount numeric DEFAULT 0,
  p_interest_amount numeric DEFAULT 0,
  p_penalty_amount numeric DEFAULT 0,
  p_excess_amount numeric DEFAULT 0,
  p_repayment_type varchar DEFAULT 'partial_principal',
  p_payment_date date DEFAULT now()::date,
  p_notes text DEFAULT null
)
RETURNS table (
  repayment_id uuid,
  new_remaining_principal numeric,
  success boolean,
  message text
) 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
  v_current_loan_amount numeric;
  v_new_remaining numeric;
  v_repayment_id uuid;
BEGIN
  -- 验证贷款是否存在
  SELECT loan_amount INTO v_current_loan_amount
  FROM public.customers 
  WHERE id = p_customer_id;
  
  IF v_current_loan_amount IS NULL THEN
    RETURN QUERY SELECT null::uuid, null::numeric, false, '客户或贷款不存在';
    RETURN;
  END IF;

  -- 插入还款记录（移除 remaining_principal 字段）
  INSERT INTO public.repayments(
    customer_id,
    loan_id,
    amount,
    principal_amount,
    interest_amount,
    penalty_amount,
    excess_amount,
    payment_date,
    due_date,
    repayment_type,
    notes
  )
  VALUES (
    p_customer_id,
    p_loan_id,
    p_amount,
    p_principal_amount,
    p_interest_amount,
    p_penalty_amount,
    p_excess_amount,
    p_payment_date,
    p_payment_date, -- due_date 设为相同
    p_repayment_type,
    p_notes
  )
  RETURNING id INTO v_repayment_id;

  -- 计算新的剩余本金
  v_new_remaining := GREATEST(v_current_loan_amount - p_principal_amount, 0);

  -- 如果全额结清，更新客户状态
  IF v_new_remaining <= 0 OR p_repayment_type = 'full_settlement' THEN
    UPDATE public.customers 
    SET status = 'cleared'
    WHERE id = p_customer_id;
  END IF;

  -- 返回结果
  RETURN QUERY SELECT v_repayment_id, v_new_remaining, true, '还款处理成功';
  RETURN;

EXCEPTION WHEN OTHERS THEN
  -- 错误处理
  RETURN QUERY SELECT null::uuid, null::numeric, false, SQLERRM;
  RETURN;
END $$;

-- 2. 创建权限策略（如果需要）
-- 注意：RPC函数使用 SECURITY DEFINER，会以定义者权限运行

-- 3. 测试函数
DO $$
BEGIN
  RAISE NOTICE '✅ process_repayment 函数创建成功！';
  RAISE NOTICE 'ℹ️  可以通过 supabase.rpc("process_repayment", {...}) 调用';
END $$;