-- =========================================================================
-- 修复剩余余额自动计算功能
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 为客户表添加剩余余额字段
ALTER TABLE public.customers 
ADD COLUMN IF NOT EXISTS remaining_balance DECIMAL(15,2) DEFAULT 0;

-- 2. 初始化现有客户的剩余余额
UPDATE public.customers 
SET remaining_balance = COALESCE(loan_amount, 0)
WHERE remaining_balance = 0;

-- 3. 删除旧的RPC函数
DROP FUNCTION IF EXISTS public.process_repayment(uuid, uuid, numeric, numeric, numeric, numeric, numeric, varchar, date, text);

-- 4. 创建修复后的RPC函数
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
  new_remaining_balance numeric,  -- 修复：改为 new_remaining_balance
  success boolean,
  message text
) 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
  v_current_remaining numeric;
  v_new_remaining numeric;
  v_repayment_id uuid;
BEGIN
  -- 获取当前剩余余额
  SELECT COALESCE(remaining_balance, loan_amount, 0) INTO v_current_remaining
  FROM public.customers 
  WHERE id = p_customer_id;
  
  IF v_current_remaining IS NULL THEN
    RETURN QUERY SELECT null::uuid, null::numeric, false, '客户不存在';
    RETURN;
  END IF;

  -- 计算新的剩余余额（本金部分）
  v_new_remaining := GREATEST(v_current_remaining - p_principal_amount, 0);

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
    p_payment_date,
    p_repayment_type,
    p_notes
  )
  RETURNING id INTO v_repayment_id;

  -- 更新客户的剩余余额
  UPDATE public.customers 
  SET remaining_balance = v_new_remaining,
      updated_at = NOW()
  WHERE id = p_customer_id;

  -- 如果全额结清，更新客户状态
  IF v_new_remaining <= 0 OR p_repayment_type = 'full_settlement' THEN
    UPDATE public.customers 
    SET status = 'cleared',
        remaining_balance = 0,
        updated_at = NOW()
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

-- 5. 创建触发器：当客户创建时自动设置剩余余额
CREATE OR REPLACE FUNCTION public.set_initial_remaining_balance()
RETURNS TRIGGER AS $$
BEGIN
  NEW.remaining_balance := COALESCE(NEW.loan_amount, 0);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_initial_remaining_balance ON public.customers;
CREATE TRIGGER trigger_set_initial_remaining_balance
  BEFORE INSERT ON public.customers
  FOR EACH ROW
  EXECUTE FUNCTION public.set_initial_remaining_balance();

-- 6. 验证函数创建成功
DO $$
BEGIN
  -- 检查函数是否存在
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'process_repayment') THEN
    RAISE NOTICE '✅ process_repayment 函数已创建成功';
  ELSE
    RAISE NOTICE '❌ process_repayment 函数创建失败';
  END IF;
  
  -- 检查触发器是否存在
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_set_initial_remaining_balance') THEN
    RAISE NOTICE '✅ 剩余余额触发器已创建成功';
  ELSE
    RAISE NOTICE '❌ 剩余余额触发器创建失败';
  END IF;
END $$;

SELECT '🎉 剩余余额自动计算功能修复完成！' as status;
