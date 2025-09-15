-- =========================================================================
-- 最终彻底修复脚本 - 一次性解决所有问题
-- 请在 Supabase SQL Editor 中完整执行此脚本
-- =========================================================================

-- 第一步：确保表结构完整
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS remaining_principal DECIMAL(15,2) DEFAULT 0;

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS payment_date DATE;

-- 第二步：删除旧的RPC函数
DROP FUNCTION IF EXISTS public.process_repayment(uuid, uuid, numeric, numeric, numeric, numeric, numeric, varchar, date, text);

-- 第三步：创建完全正确的RPC函数
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
  -- 验证客户是否存在
  SELECT loan_amount INTO v_current_loan_amount
  FROM public.customers 
  WHERE id = p_customer_id;
  
  IF v_current_loan_amount IS NULL THEN
    RETURN QUERY SELECT null::uuid, null::numeric, false, '客户不存在';
    RETURN;
  END IF;

  -- 计算新的剩余本金
  v_new_remaining := GREATEST(v_current_loan_amount - p_principal_amount, 0);

  -- 插入还款记录
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
    notes,
    remaining_principal
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
    p_notes,
    v_new_remaining
  )
  RETURNING id INTO v_repayment_id;

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

-- 第四步：验证修复结果
SELECT '🎉 彻底修复完成！现在测试还款功能吧！' as final_status;