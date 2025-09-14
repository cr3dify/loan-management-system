-- 为客户表添加贷款相关字段
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 检查当前客户表结构
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'customers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. 添加贷款相关字段
ALTER TABLE public.customers 
ADD COLUMN IF NOT EXISTS loan_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS interest_rate DECIMAL(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS loan_method VARCHAR(20) DEFAULT 'mode1',
ADD COLUMN IF NOT EXISTS deposit_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS received_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS suggested_payment DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_repayment DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS periods INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS principal_rate_per_period DECIMAL(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS number_of_periods INTEGER DEFAULT 0;

-- 3. 添加约束
ALTER TABLE public.customers 
ADD CONSTRAINT check_loan_method CHECK (loan_method IN ('mode1', 'mode2'));

-- 4. 更新现有记录的默认值
UPDATE public.customers 
SET 
  loan_amount = COALESCE(loan_amount, 0),
  interest_rate = COALESCE(interest_rate, 0),
  loan_method = COALESCE(loan_method, 'mode1'),
  deposit_amount = COALESCE(deposit_amount, 0),
  received_amount = COALESCE(received_amount, 0),
  suggested_payment = COALESCE(suggested_payment, 0),
  total_repayment = COALESCE(total_repayment, 0),
  periods = COALESCE(periods, 0),
  principal_rate_per_period = COALESCE(principal_rate_per_period, 0),
  number_of_periods = COALESCE(number_of_periods, 0);

-- 5. 验证字段添加成功
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'customers' 
AND table_schema = 'public'
AND column_name IN ('loan_amount', 'interest_rate', 'loan_method', 'deposit_amount', 'received_amount', 'suggested_payment', 'total_repayment', 'periods', 'principal_rate_per_period', 'number_of_periods')
ORDER BY column_name;
