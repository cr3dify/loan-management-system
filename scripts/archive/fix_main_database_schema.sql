-- 修正主数据库结构以匹配前端期望
-- 此脚本需要在主数据库脚本执行后运行

-- ===================================
-- 第一部分：修正客户表结构
-- ===================================

-- 1. 为客户表添加缺少的贷款相关字段
ALTER TABLE public.customers 
ADD COLUMN IF NOT EXISTS loan_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS interest_rate DECIMAL(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS loan_method VARCHAR(20) DEFAULT 'scenario_a',
ADD COLUMN IF NOT EXISTS deposit_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS received_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS suggested_payment DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_repayment DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS periods INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS principal_rate_per_period DECIMAL(5,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS number_of_periods INTEGER DEFAULT 0;

-- 2. 修正客户表字段名以匹配前端
-- 将 name 改为 full_name，id_card 改为 id_number
DO $$
BEGIN
    -- 检查并添加 full_name 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'customers' AND column_name = 'full_name') THEN
        ALTER TABLE public.customers ADD COLUMN full_name VARCHAR(100);
        UPDATE public.customers SET full_name = name;
        ALTER TABLE public.customers ALTER COLUMN full_name SET NOT NULL;
    END IF;
    
    -- 检查并添加 id_number 字段
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'customers' AND column_name = 'id_number') THEN
        ALTER TABLE public.customers ADD COLUMN id_number VARCHAR(50);
        UPDATE public.customers SET id_number = id_card;
        ALTER TABLE public.customers ALTER COLUMN id_number SET NOT NULL;
    END IF;
END $$;

-- 3. 更新客户状态枚举以匹配前端期望
ALTER TABLE public.customers 
DROP CONSTRAINT IF EXISTS customers_status_check;

ALTER TABLE public.customers 
ADD CONSTRAINT customers_status_check 
CHECK (status IN ('normal', 'overdue', 'cleared', 'negotiating', 'bad_debt'));

-- 4. 添加贷款方法约束
ALTER TABLE public.customers 
ADD CONSTRAINT check_customer_loan_method 
CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c'));

-- ===================================
-- 第二部分：修正贷款表结构
-- ===================================

-- 5. 修正贷款表的字段命名
-- 将 loan_type 改为 loan_method，并更新约束
ALTER TABLE public.loans 
DROP CONSTRAINT IF EXISTS loans_loan_type_check;

-- 如果 loan_method 字段不存在，则添加
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'loans' AND column_name = 'loan_method') THEN
        ALTER TABLE public.loans ADD COLUMN loan_method VARCHAR(20) DEFAULT 'scenario_a';
        UPDATE public.loans SET loan_method = 
            CASE 
                WHEN loan_type = 'type_a' THEN 'scenario_a'
                WHEN loan_type = 'type_b' THEN 'scenario_b'
                ELSE 'scenario_a'
            END;
    END IF;
END $$;

-- 添加新的约束
ALTER TABLE public.loans 
ADD CONSTRAINT check_loans_loan_method 
CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c'));

-- 6. 修正字段名映射
-- 将 collateral_amount 改为 deposit_amount 以匹配前端
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'loans' AND column_name = 'deposit_amount') THEN
        ALTER TABLE public.loans ADD COLUMN deposit_amount DECIMAL(15,2) DEFAULT 0;
        UPDATE public.loans SET deposit_amount = collateral_amount;
    END IF;
END $$;

-- ===================================
-- 第三部分：修正合同模板表
-- ===================================

-- 7. 更新合同模板的贷款类型
UPDATE public.contract_templates 
SET loan_type = CASE 
    WHEN loan_type = 'type_a' THEN 'scenario_a'
    WHEN loan_type = 'type_b' THEN 'scenario_b'
    ELSE 'scenario_a'
END;

ALTER TABLE public.contract_templates 
DROP CONSTRAINT IF EXISTS contract_templates_loan_type_check;

ALTER TABLE public.contract_templates 
ADD CONSTRAINT check_contract_loan_type 
CHECK (loan_type IN ('scenario_a', 'scenario_b', 'scenario_c'));

-- ===================================
-- 第四部分：更新计算函数
-- ===================================

-- 8. 修正计算函数以支持新的贷款场景
CREATE OR REPLACE FUNCTION calculate_actual_amount(
    p_loan_amount DECIMAL(15,2),
    p_interest_rate DECIMAL(5,2),
    p_deposit_amount DECIMAL(15,2),
    p_cycle_days INTEGER,
    p_loan_method VARCHAR(20)
) RETURNS DECIMAL(15,2) AS $$
DECLARE
    interest_amount DECIMAL(15,2);
    actual_amount DECIMAL(15,2);
BEGIN
    -- 计算利息金额
    interest_amount := p_loan_amount * (p_interest_rate / 100);
    
    -- 根据贷款场景计算实际到手金额
    IF p_loan_method = 'scenario_a' THEN
        -- 场景A：利息+押金 (先扣息+押金)
        actual_amount := p_loan_amount - interest_amount - p_deposit_amount;
    ELSIF p_loan_method = 'scenario_b' THEN
        -- 场景B：只收利息 (先扣息，无押金)
        actual_amount := p_loan_amount - interest_amount;
    ELSIF p_loan_method = 'scenario_c' THEN
        -- 场景C：只收押金 (无利息，只收押金)
        actual_amount := p_loan_amount - p_deposit_amount;
    ELSE
        -- 默认场景A
        actual_amount := p_loan_amount - interest_amount - p_deposit_amount;
    END IF;
    
    RETURN GREATEST(actual_amount, 0); -- 确保不返回负值
END;
$$ LANGUAGE plpgsql;

-- 9. 更新贷款自动计算触发器函数
CREATE OR REPLACE FUNCTION auto_calculate_loan_details()
RETURNS TRIGGER AS $$
BEGIN
    -- 自动计算实际到手金额
    NEW.actual_amount := calculate_actual_amount(
        NEW.loan_amount,
        NEW.interest_rate,
        NEW.deposit_amount,
        NEW.cycle_days,
        NEW.loan_method
    );
    
    -- 初始化剩余本金
    NEW.remaining_principal := NEW.loan_amount;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 第五部分：数据迁移和同步
-- ===================================

-- 10. 创建客户贷款数据同步函数
CREATE OR REPLACE FUNCTION sync_customer_loan_data()
RETURNS void AS $$
DECLARE
    loan_record RECORD;
BEGIN
    -- 将贷款表数据同步到客户表
    FOR loan_record IN 
        SELECT DISTINCT ON (customer_id) *
        FROM public.loans
        WHERE status = 'active'
        ORDER BY customer_id, created_at DESC
    LOOP
        UPDATE public.customers 
        SET 
            loan_amount = loan_record.loan_amount,
            interest_rate = loan_record.interest_rate,
            loan_method = loan_record.loan_method,
            deposit_amount = loan_record.deposit_amount,
            received_amount = loan_record.actual_amount,
            suggested_payment = loan_record.loan_amount / NULLIF(loan_record.cycle_days, 0) * 30, -- 月还款估算
            total_repayment = loan_record.loan_amount + (loan_record.loan_amount * loan_record.interest_rate / 100),
            periods = GREATEST(loan_record.cycle_days / 30, 1), -- 期数估算
            principal_rate_per_period = 10, -- 默认每期10%
            number_of_periods = GREATEST(loan_record.cycle_days / 30, 1)
        WHERE id = loan_record.customer_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 执行数据同步
SELECT sync_customer_loan_data();

-- ===================================
-- 第六部分：创建视图确保数据一致性
-- ===================================

-- 11. 创建客户贷款统一视图
CREATE OR REPLACE VIEW public.customer_loan_view AS
SELECT 
    c.id,
    c.customer_code,
    c.customer_number,
    c.full_name,
    c.id_number,
    c.phone,
    c.address,
    c.loan_amount,
    c.interest_rate,
    c.loan_method,
    c.deposit_amount,
    c.received_amount,
    c.suggested_payment,
    c.total_repayment,
    c.periods,
    c.principal_rate_per_period,
    c.number_of_periods,
    c.status,
    c.notes,
    c.approval_status,
    c.contract_signed,
    c.negotiation_terms,
    c.loss_amount,
    c.created_at,
    c.updated_at,
    l.remaining_principal,
    l.disbursement_date,
    l.actual_amount as loan_actual_amount
FROM public.customers c
LEFT JOIN LATERAL (
    SELECT * FROM public.loans 
    WHERE customer_id = c.id 
    AND status = 'active' 
    ORDER BY created_at DESC 
    LIMIT 1
) l ON true;

-- 12. 添加索引优化查询性能
CREATE INDEX IF NOT EXISTS idx_customers_loan_method ON public.customers(loan_method);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_loans_loan_method ON public.loans(loan_method);

-- ===================================
-- 第七部分：验证和报告
-- ===================================

-- 13. 创建数据验证报告
CREATE OR REPLACE VIEW public.schema_validation_report AS
SELECT 
    'customers' as table_name,
    'loan_method' as field_name,
    loan_method as value,
    COUNT(*) as count
FROM public.customers 
WHERE loan_method IS NOT NULL
GROUP BY loan_method

UNION ALL

SELECT 
    'loans' as table_name,
    'loan_method' as field_name,
    loan_method as value,
    COUNT(*) as count
FROM public.loans 
WHERE loan_method IS NOT NULL
GROUP BY loan_method

UNION ALL

SELECT 
    'repayments' as table_name,
    'repayment_type' as field_name,
    repayment_type as value,
    COUNT(*) as count
FROM public.repayments 
GROUP BY repayment_type

ORDER BY table_name, field_name, value;

-- 14. 插入修正完成标记
INSERT INTO public.system_settings (setting_key, setting_value, description, updated_at)
VALUES (
    'schema_fixed_at',
    NOW()::text,
    '数据库结构修正完成时间 - 客户表和贷款表结构已统一',
    NOW()
) ON CONFLICT (setting_key) DO UPDATE SET 
    setting_value = EXCLUDED.setting_value,
    updated_at = EXCLUDED.updated_at;

-- 显示修正结果
SELECT 'Database Schema Fix Complete!' as status;
SELECT * FROM public.schema_validation_report;

-- 显示客户表新结构
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'customers' 
ORDER BY ordinal_position;