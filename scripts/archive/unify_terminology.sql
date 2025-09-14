-- 统一贷款管理系统术语
-- 执行此脚本来更新数据库约束以支持新的术语

-- 1. 首先删除现有约束（如果存在）
ALTER TABLE public.customers 
DROP CONSTRAINT IF EXISTS check_loan_method;

-- 2. 先更新现有记录的贷款模式（在添加新约束之前）
UPDATE public.customers 
SET loan_method = CASE 
    WHEN loan_method = 'mode1' THEN 'scenario_a'
    WHEN loan_method = 'mode2' THEN 'scenario_b'
    WHEN loan_method IS NULL THEN 'scenario_a'  -- 处理NULL值
    WHEN loan_method = '' THEN 'scenario_a'     -- 处理空字符串
    ELSE 'scenario_a'  -- 其他所有情况的默认值
END;

-- 3. 现在添加新的约束（数据已经符合要求）
ALTER TABLE public.customers 
ADD CONSTRAINT check_loan_method CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c'));

-- 4. 更新贷款表的贷款模式约束（如果存在）
-- 首先检查表是否存在并更新数据
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loans') THEN
        -- 删除现有约束
        ALTER TABLE public.loans DROP CONSTRAINT IF EXISTS check_loan_type;
        
        -- 更新现有数据
        UPDATE public.loans 
        SET loan_type = CASE 
            WHEN loan_type = 'mode1' THEN 'scenario_a'
            WHEN loan_type = 'mode2' THEN 'scenario_b'
            WHEN loan_type = 'type_a' THEN 'scenario_a'
            WHEN loan_type = 'type_b' THEN 'scenario_b'
            WHEN loan_type IS NULL THEN 'scenario_a'
            WHEN loan_type = '' THEN 'scenario_a'
            ELSE 'scenario_a'
        END;
        
        -- 添加新约束
        ALTER TABLE public.loans 
        ADD CONSTRAINT check_loan_type CHECK (loan_type IN ('scenario_a', 'scenario_b', 'scenario_c'));
    END IF;
END $$;

-- 5. 更新还款记录表的还款类型约束
-- 首先删除现有约束
ALTER TABLE public.repayments 
DROP CONSTRAINT IF EXISTS check_repayment_type;

-- 确保所有现有记录的repayment_type字段都有效
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

-- 现在添加新约束
ALTER TABLE public.repayments 
ADD CONSTRAINT check_repayment_type CHECK (repayment_type IN ('interest_only', 'partial_principal', 'full_settlement'));

-- 6. 如果存在旧的 payment_type 字段，则删除并更新为 repayment_type
-- 检查字段是否存在，如果存在则进行数据迁移
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'repayments' AND column_name = 'payment_type') THEN
        
        -- 更新数据映射
        UPDATE public.repayments 
        SET repayment_type = CASE 
            WHEN payment_type = 'regular' THEN 'partial_principal'
            WHEN payment_type = 'partial' THEN 'partial_principal'
            WHEN payment_type = 'full' THEN 'full_settlement'
            WHEN payment_type = 'interest_only' THEN 'interest_only'
            ELSE 'partial_principal'  -- 默认值
        END;
        
        -- 删除旧字段
        ALTER TABLE public.repayments DROP COLUMN payment_type;
    END IF;
END $$;

-- 7. 更新系统设置表中的相关配置（如果有）
UPDATE public.system_settings 
SET setting_value = REPLACE(REPLACE(setting_value, 'mode1', 'scenario_a'), 'mode2', 'scenario_b')
WHERE setting_key LIKE '%loan_method%' OR setting_key LIKE '%payment_type%';

-- 8. 创建数据验证视图，确保数据一致性
CREATE OR REPLACE VIEW public.data_validation_summary AS
SELECT 
    'customers' as table_name,
    'loan_method' as field_name,
    loan_method as value,
    COUNT(*) as count
FROM public.customers 
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

-- 9. 插入审计记录
INSERT INTO public.system_settings (setting_key, setting_value, description, updated_at)
VALUES (
    'terminology_unified_at',
    NOW()::text,
    '术语统一完成时间 - 贷款模式和还款类型已统一',
    NOW()
) ON CONFLICT (setting_key) DO UPDATE SET 
    setting_value = EXCLUDED.setting_value,
    updated_at = EXCLUDED.updated_at;

-- 10. 显示统一后的数据分布
SELECT 'Terminology Unification Complete!' as status;
SELECT * FROM public.data_validation_summary;