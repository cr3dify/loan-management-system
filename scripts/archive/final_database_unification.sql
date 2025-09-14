-- 贷款管理系统最终统一脚本
-- 此脚本适配您的主数据库结构，修正不匹配问题并统一术语
-- 请在主数据库脚本执行完成后运行此脚本

-- ==========================================
-- 第一阶段：修正数据库结构以匹配前端期望
-- ==========================================

-- 1. 为客户表添加前端期望的贷款相关字段
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

-- 2. 添加前端期望的字段名（如果不存在）
DO $$
BEGIN
    -- 添加 full_name 字段（前端期望）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'customers' AND column_name = 'full_name') THEN
        ALTER TABLE public.customers ADD COLUMN full_name VARCHAR(100);
        -- 从现有 name 字段复制数据
        UPDATE public.customers SET full_name = name WHERE name IS NOT NULL;
        -- 设置非空约束
        ALTER TABLE public.customers ALTER COLUMN full_name SET NOT NULL;
    END IF;
    
    -- 添加 id_number 字段（前端期望）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'customers' AND column_name = 'id_number') THEN
        ALTER TABLE public.customers ADD COLUMN id_number VARCHAR(50);
        -- 从现有 id_card 字段复制数据
        UPDATE public.customers SET id_number = id_card WHERE id_card IS NOT NULL;
        -- 设置非空约束
        ALTER TABLE public.customers ALTER COLUMN id_number SET NOT NULL;
    END IF;
END $$;

-- 3. 修正客户状态枚举以匹配前端期望
ALTER TABLE public.customers 
DROP CONSTRAINT IF EXISTS customers_status_check;

-- 添加与前端一致的状态约束
ALTER TABLE public.customers 
ADD CONSTRAINT customers_status_check 
CHECK (status IN ('normal', 'overdue', 'cleared', 'negotiating', 'bad_debt'));

-- 更新现有状态数据
UPDATE public.customers 
SET status = CASE 
    WHEN status = 'completed' THEN 'cleared'  -- 映射到前端期望的状态
    WHEN status IS NULL THEN 'normal'
    ELSE status
END;

-- ==========================================
-- 第二阶段：统一贷款模式术语
-- ==========================================

-- 4. 统一客户表的贷款模式术语
-- 删除现有约束
ALTER TABLE public.customers 
DROP CONSTRAINT IF EXISTS check_loan_method;
DROP CONSTRAINT IF EXISTS check_customer_loan_method;

-- 更新现有数据到新术语
UPDATE public.customers 
SET loan_method = CASE 
    WHEN loan_method = 'mode1' THEN 'scenario_a'
    WHEN loan_method = 'mode2' THEN 'scenario_b'
    WHEN loan_method IS NULL THEN 'scenario_a'
    WHEN loan_method = '' THEN 'scenario_a'
    ELSE 'scenario_a'
END;

-- 添加新的约束
ALTER TABLE public.customers 
ADD CONSTRAINT check_customer_loan_method 
CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c'));

-- 5. 统一贷款表的术语
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loans') THEN
        -- 删除现有约束
        ALTER TABLE public.loans DROP CONSTRAINT IF EXISTS loans_loan_type_check;
        ALTER TABLE public.loans DROP CONSTRAINT IF EXISTS check_loan_type;
        
        -- 添加 loan_method 字段（如果不存在）
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'loans' AND column_name = 'loan_method') THEN
            ALTER TABLE public.loans ADD COLUMN loan_method VARCHAR(20) DEFAULT 'scenario_a';
        END IF;
        
        -- 添加 deposit_amount 字段（如果不存在）
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'loans' AND column_name = 'deposit_amount') THEN
            ALTER TABLE public.loans ADD COLUMN deposit_amount DECIMAL(15,2) DEFAULT 0;
            -- 从 collateral_amount 复制数据
            UPDATE public.loans SET deposit_amount = collateral_amount WHERE collateral_amount IS NOT NULL;
        END IF;
        
        -- 更新贷款类型数据
        UPDATE public.loans 
        SET loan_method = CASE 
            WHEN loan_type = 'type_a' THEN 'scenario_a'
            WHEN loan_type = 'type_b' THEN 'scenario_b'
            WHEN loan_method = 'mode1' THEN 'scenario_a'
            WHEN loan_method = 'mode2' THEN 'scenario_b'
            WHEN loan_method IS NULL THEN 'scenario_a'
            WHEN loan_method = '' THEN 'scenario_a'
            ELSE 'scenario_a'
        END;
        
        -- 添加新约束
        ALTER TABLE public.loans 
        ADD CONSTRAINT check_loans_loan_method 
        CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c'));
    END IF;
END $$;

-- ==========================================
-- 第三阶段：统一还款类型术语
-- ==========================================

-- 6. 统一还款记录表的还款类型
-- 删除现有约束
ALTER TABLE public.repayments 
DROP CONSTRAINT IF EXISTS repayments_repayment_type_check;
ALTER TABLE public.repayments 
DROP CONSTRAINT IF EXISTS check_repayment_type;

-- 更新现有还款类型数据
UPDATE public.repayments 
SET repayment_type = CASE 
    WHEN repayment_type = 'regular' THEN 'partial_principal'
    WHEN repayment_type = 'partial' THEN 'partial_principal'
    WHEN repayment_type = 'full' THEN 'full_settlement'
    WHEN repayment_type = 'interest_only' THEN 'interest_only'
    WHEN repayment_type IS NULL THEN 'partial_principal'
    WHEN repayment_type = '' THEN 'partial_principal'
    ELSE 'partial_principal'
END;

-- 添加新约束
ALTER TABLE public.repayments 
ADD CONSTRAINT check_repayments_repayment_type 
CHECK (repayment_type IN ('interest_only', 'partial_principal', 'full_settlement'));

-- 7. 处理可能存在的旧 payment_type 字段
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'repayments' AND column_name = 'payment_type') THEN
        
        -- 确保 repayment_type 字段存在
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'repayments' AND column_name = 'repayment_type') THEN
            ALTER TABLE public.repayments ADD COLUMN repayment_type VARCHAR(20) DEFAULT 'partial_principal';
        END IF;
        
        -- 数据迁移：从 payment_type 到 repayment_type
        UPDATE public.repayments 
        SET repayment_type = CASE 
            WHEN payment_type = 'regular' THEN 'partial_principal'
            WHEN payment_type = 'partial' THEN 'partial_principal'
            WHEN payment_type = 'full' THEN 'full_settlement'
            WHEN payment_type = 'interest_only' THEN 'interest_only'
            ELSE 'partial_principal'
        END;
        
        -- 删除旧字段
        ALTER TABLE public.repayments DROP COLUMN payment_type;
    END IF;
END $$;

-- ==========================================
-- 第四阶段：更新计算函数以支持新术语
-- ==========================================

-- 8. 更新贷款计算函数以支持三种场景
CREATE OR REPLACE FUNCTION calculate_actual_amount(
    p_loan_amount DECIMAL(15,2),
    p_interest_rate DECIMAL(5,2),
    p_deposit_amount DECIMAL(15,2),
    p_cycle_days INTEGER DEFAULT 30,
    p_loan_method VARCHAR(20) DEFAULT 'scenario_a'
) RETURNS DECIMAL(15,2) AS $$
DECLARE
    interest_amount DECIMAL(15,2);
    actual_amount DECIMAL(15,2);
BEGIN
    -- 计算利息金额
    interest_amount := p_loan_amount * (p_interest_rate / 100);
    
    -- 根据贷款场景计算实际到手金额
    CASE p_loan_method
        WHEN 'scenario_a' THEN
            -- 场景A：利息+押金 (先扣息+押金)
            actual_amount := p_loan_amount - interest_amount - p_deposit_amount;
        WHEN 'scenario_b' THEN
            -- 场景B：只收利息 (先扣息，无押金)
            actual_amount := p_loan_amount - interest_amount;
        WHEN 'scenario_c' THEN
            -- 场景C：只收押金 (无利息，只收押金)
            actual_amount := p_loan_amount - p_deposit_amount;
        ELSE
            -- 默认场景A
            actual_amount := p_loan_amount - interest_amount - p_deposit_amount;
    END CASE;
    
    RETURN GREATEST(actual_amount, 0); -- 确保不返回负值
END;
$$ LANGUAGE plpgsql;

-- 9. 更新贷款自动计算触发器
CREATE OR REPLACE FUNCTION auto_calculate_loan_details()
RETURNS TRIGGER AS $$
BEGIN
    -- 确保字段存在并设置默认值
    IF NEW.loan_method IS NULL THEN
        NEW.loan_method := 'scenario_a';
    END IF;
    
    IF NEW.deposit_amount IS NULL THEN
        NEW.deposit_amount := COALESCE(NEW.collateral_amount, 0);
    END IF;
    
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

-- ==========================================
-- 第五阶段：数据同步和一致性保证
-- ==========================================

-- 10. 创建客户贷款数据同步函数
CREATE OR REPLACE FUNCTION sync_customer_loan_data()
RETURNS void AS $$
DECLARE
    loan_record RECORD;
BEGIN
    -- 同步活跃贷款的数据到客户表
    FOR loan_record IN 
        SELECT DISTINCT ON (customer_id) 
            customer_id,
            loan_amount,
            interest_rate,
            loan_method,
            deposit_amount,
            actual_amount,
            cycle_days
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
            -- 计算建议还款金额（简化：月还款）
            suggested_payment = CASE 
                WHEN loan_record.cycle_days > 0 THEN 
                    (loan_record.loan_amount / GREATEST(loan_record.cycle_days / 30.0, 1))
                ELSE loan_record.loan_amount / 10
            END,
            total_repayment = loan_record.loan_amount + (loan_record.loan_amount * loan_record.interest_rate / 100),
            periods = GREATEST(loan_record.cycle_days / 30, 1),
            principal_rate_per_period = 10.0, -- 默认每期10%
            number_of_periods = GREATEST(loan_record.cycle_days / 30, 1)
        WHERE id = loan_record.customer_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 执行数据同步
SELECT sync_customer_loan_data();

-- ==========================================
-- 第六阶段：更新合同模板和系统设置
-- ==========================================

-- 11. 更新合同模板的贷款类型
UPDATE public.contract_templates 
SET loan_type = CASE 
    WHEN loan_type = 'type_a' THEN 'scenario_a'
    WHEN loan_type = 'type_b' THEN 'scenario_b'
    ELSE 'scenario_a'
END;

-- 更新合同模板约束
ALTER TABLE public.contract_templates 
DROP CONSTRAINT IF EXISTS contract_templates_loan_type_check;

ALTER TABLE public.contract_templates 
ADD CONSTRAINT check_contract_templates_loan_type 
CHECK (loan_type IN ('scenario_a', 'scenario_b', 'scenario_c'));

-- 12. 更新系统设置中的相关配置
UPDATE public.system_settings 
SET setting_value = REPLACE(REPLACE(REPLACE(setting_value, 'mode1', 'scenario_a'), 'mode2', 'scenario_b'), 'type_a', 'scenario_a')
WHERE setting_key LIKE '%loan%' OR setting_key LIKE '%payment%' OR setting_key LIKE '%type%';

-- ==========================================
-- 第七阶段：创建验证视图和索引优化
-- ==========================================

-- 13. 创建全面的数据验证视图
CREATE OR REPLACE VIEW public.unified_validation_report AS
SELECT 
    'customers' as table_name,
    'loan_method' as field_name,
    loan_method as value,
    COUNT(*) as count,
    'loan_method字段统计' as description
FROM public.customers 
WHERE loan_method IS NOT NULL
GROUP BY loan_method

UNION ALL

SELECT 
    'customers' as table_name,
    'status' as field_name,
    status as value,
    COUNT(*) as count,
    '客户状态统计' as description
FROM public.customers 
GROUP BY status

UNION ALL

SELECT 
    'loans' as table_name,
    'loan_method' as field_name,
    loan_method as value,
    COUNT(*) as count,
    '贷款方法统计' as description
FROM public.loans 
WHERE loan_method IS NOT NULL
GROUP BY loan_method

UNION ALL

SELECT 
    'repayments' as table_name,
    'repayment_type' as field_name,
    repayment_type as value,
    COUNT(*) as count,
    '还款类型统计' as description
FROM public.repayments 
GROUP BY repayment_type

ORDER BY table_name, field_name, value;

-- 14. 添加性能优化索引
CREATE INDEX IF NOT EXISTS idx_customers_loan_method ON public.customers(loan_method);
CREATE INDEX IF NOT EXISTS idx_customers_full_name ON public.customers(full_name);
CREATE INDEX IF NOT EXISTS idx_customers_id_number ON public.customers(id_number);
CREATE INDEX IF NOT EXISTS idx_loans_loan_method ON public.loans(loan_method) WHERE loan_method IS NOT NULL;

-- ==========================================
-- 第八阶段：审计和完成标记
-- ==========================================

-- 15. 插入完成标记和审计记录
INSERT INTO public.system_settings (setting_key, setting_value, description, updated_at)
VALUES 
    ('database_unified_at', NOW()::text, '数据库结构和术语统一完成时间', NOW()),
    ('frontend_backend_aligned', 'true', '前后端数据结构已对齐', NOW()),
    ('terminology_version', '2.0', '术语标准化版本', NOW())
ON CONFLICT (setting_key) DO UPDATE SET 
    setting_value = EXCLUDED.setting_value,
    updated_at = EXCLUDED.updated_at;

-- 16. 最终验证和报告
SELECT 'Database Unification Complete!' as status, NOW() as completed_at;

-- 显示统一后的数据分布
SELECT '=== 数据统一验证报告 ===' as report_title;
SELECT * FROM public.unified_validation_report ORDER BY table_name, field_name, value;

-- 显示客户表结构验证
SELECT '=== 客户表结构验证 ===' as structure_check;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'customers' 
AND column_name IN ('full_name', 'id_number', 'loan_method', 'loan_amount', 'status')
ORDER BY column_name;

-- 显示约束验证
SELECT '=== 约束验证 ===' as constraint_check;
SELECT 
    constraint_name, 
    table_name, 
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name IN ('customers', 'loans', 'repayments', 'contract_templates')
AND constraint_type = 'CHECK'
ORDER BY table_name, constraint_name;