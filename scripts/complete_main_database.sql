-- =========================================================================
-- 贷款管理系统完整数据库脚本 v2.0
-- 包含：基础表结构 + 术语统一 + 前后端对齐 + 完整业务逻辑
-- 适用于：全新部署或现有数据库升级
-- =========================================================================

-- =========================================================================
-- 第一部分：核心表结构（增强版）
-- =========================================================================

-- 1. 用户表
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'employee' CHECK (role IN ('admin', 'secretary', 'employee')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 客户表（完整版，包含所有前端期望字段）
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_code VARCHAR(50) UNIQUE NOT NULL,
    customer_number VARCHAR(20) UNIQUE NOT NULL,
    -- 基础信息（兼容旧字段名）
    name VARCHAR(100), -- 保留旧字段兼容
    full_name VARCHAR(100) NOT NULL, -- 前端期望字段
    id_card VARCHAR(50), -- 保留旧字段兼容  
    id_number VARCHAR(50) NOT NULL, -- 前端期望字段
    phone VARCHAR(20) NOT NULL,
    address TEXT NOT NULL,
    notes TEXT,
    -- 贷款相关字段（前端期望）
    loan_amount DECIMAL(15,2) DEFAULT 0,
    interest_rate DECIMAL(5,2) DEFAULT 0,
    loan_method VARCHAR(20) DEFAULT 'scenario_a' CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c')),
    deposit_amount DECIMAL(15,2) DEFAULT 0,
    received_amount DECIMAL(15,2) DEFAULT 0,
    suggested_payment DECIMAL(15,2) DEFAULT 0,
    total_repayment DECIMAL(15,2) DEFAULT 0,
    periods INTEGER DEFAULT 0,
    principal_rate_per_period DECIMAL(5,2) DEFAULT 0,
    number_of_periods INTEGER DEFAULT 0,
    -- 状态管理
    status VARCHAR(20) DEFAULT 'normal' CHECK (status IN ('normal', 'overdue', 'cleared', 'negotiating', 'bad_debt')),
    approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    contract_signed BOOLEAN DEFAULT FALSE,
    contract_signed_at TIMESTAMP WITH TIME ZONE,
    negotiation_terms TEXT,
    loss_amount DECIMAL(15,2) DEFAULT 0,
    -- 关联字段
    created_by UUID REFERENCES public.users(id),
    approved_by UUID REFERENCES public.users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    assigned_to UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 贷款表（增强版）
CREATE TABLE IF NOT EXISTS public.loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    loan_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    collateral_amount DECIMAL(15,2) DEFAULT 0, -- 保留兼容
    deposit_amount DECIMAL(15,2) NOT NULL, -- 统一使用此字段
    cycle_days INTEGER NOT NULL,
    loan_type VARCHAR(20), -- 保留兼容旧数据
    loan_method VARCHAR(20) NOT NULL DEFAULT 'scenario_a' CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c')),
    disbursement_date DATE NOT NULL,
    actual_amount DECIMAL(15,2) NOT NULL,
    remaining_principal DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'overdue', 'bad_debt')),
    contract_template_id UUID,
    issue_date DATE DEFAULT CURRENT_DATE,
    due_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 还款记录表（统一术语）
CREATE TABLE IF NOT EXISTS public.repayments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    repayment_type VARCHAR(20) NOT NULL CHECK (repayment_type IN ('interest_only', 'partial_principal', 'full_settlement')),
    amount DECIMAL(15,2) NOT NULL,
    interest_amount DECIMAL(15,2) DEFAULT 0,
    principal_amount DECIMAL(15,2) DEFAULT 0,
    penalty_amount DECIMAL(15,2) DEFAULT 0,
    excess_amount DECIMAL(15,2) DEFAULT 0,
    remaining_principal DECIMAL(15,2) NOT NULL,
    payment_date DATE NOT NULL,
    due_date DATE NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'cash' CHECK (payment_method IN ('cash', 'bank_transfer', 'check', 'other')),
    receipt_number VARCHAR(100),
    notes TEXT,
    processed_by UUID REFERENCES public.users(id),
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 逾期记录表
CREATE TABLE IF NOT EXISTS public.overdue_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    overdue_days INTEGER NOT NULL,
    penalty_rate DECIMAL(5,2) NOT NULL,
    penalty_amount DECIMAL(15,2) NOT NULL,
    overdue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    resolved_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'written_off')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 系统设置表
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type VARCHAR(20) DEFAULT 'string' CHECK (setting_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    updated_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. 合同模板表
CREATE TABLE IF NOT EXISTS public.contract_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    template_name VARCHAR(100) NOT NULL, -- 前端期望字段
    content TEXT NOT NULL,
    template_content TEXT NOT NULL, -- 前端期望字段
    loan_type VARCHAR(20) CHECK (loan_type IN ('scenario_a', 'scenario_b', 'scenario_c')),
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. 月度亏损统计表
CREATE TABLE IF NOT EXISTS public.monthly_losses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    total_loss_amount DECIMAL(15,2) DEFAULT 0,
    bad_debt_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(year, month)
);

-- =========================================================================
-- 第二部分：数据迁移和字段同步
-- =========================================================================

-- 确保必要的字段存在，如果不存在则添加
DO $$
BEGIN
    -- 添加 full_name 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'customers' AND column_name = 'full_name') THEN
        ALTER TABLE public.customers ADD COLUMN full_name VARCHAR(100);
    END IF;
    
    -- 添加 id_number 字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'customers' AND column_name = 'id_number') THEN
        ALTER TABLE public.customers ADD COLUMN id_number VARCHAR(50);
    END IF;
END $$;

-- 同步客户表字段（处理新旧字段兼容）
DO $$
BEGIN
    -- 删除旧的 loan_method 约束（如果存在）
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE table_name = 'customers' 
               AND constraint_name = 'customers_loan_method_check') THEN
        ALTER TABLE public.customers DROP CONSTRAINT customers_loan_method_check;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE table_name = 'customers' 
               AND constraint_name = 'check_loan_method') THEN
        ALTER TABLE public.customers DROP CONSTRAINT check_loan_method;
    END IF;
    
    -- 同步 name 到 full_name
    UPDATE public.customers SET full_name = name WHERE full_name IS NULL AND name IS NOT NULL;
    UPDATE public.customers SET name = full_name WHERE name IS NULL AND full_name IS NOT NULL;
    
    -- 同步 id_card 到 id_number  
    UPDATE public.customers SET id_number = id_card WHERE id_number IS NULL AND id_card IS NOT NULL;
    UPDATE public.customers SET id_card = id_number WHERE id_card IS NULL AND id_number IS NOT NULL;
    
    -- 状态数据迁移
    UPDATE public.customers SET status = 'cleared' WHERE status = 'completed';
    UPDATE public.customers SET status = 'normal' WHERE status IS NULL;
    
    -- 同步贷款方式术语（现在没有约束限制）
    UPDATE public.customers SET loan_method = CASE 
        WHEN loan_method = 'mode1' THEN 'scenario_a'
        WHEN loan_method = 'mode2' THEN 'scenario_b'
        WHEN loan_method IS NULL THEN 'scenario_a'
        ELSE 'scenario_a'
    END;
    
    -- 添加新的 loan_method 约束
    ALTER TABLE public.customers 
    ADD CONSTRAINT customers_loan_method_check 
    CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c'));
    
    -- 确保必要字段不为空
    UPDATE public.customers SET full_name = COALESCE(name, '未知客户') WHERE full_name IS NULL;
    UPDATE public.customers SET id_number = COALESCE(id_card, '未知证件') WHERE id_number IS NULL;
END $$;

-- 为新添加的字段设置非空约束（在数据同步后）
DO $$
BEGIN
    -- 设置 full_name 非空约束
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'customers' AND column_name = 'full_name' AND is_nullable = 'YES') THEN
        ALTER TABLE public.customers ALTER COLUMN full_name SET NOT NULL;
    END IF;
    
    -- 设置 id_number 非空约束
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'customers' AND column_name = 'id_number' AND is_nullable = 'YES') THEN
        ALTER TABLE public.customers ALTER COLUMN id_number SET NOT NULL;
    END IF;
END $$;

-- 同步贷款表字段
DO $$
BEGIN
    -- 确保 deposit_amount 字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'loans' AND column_name = 'deposit_amount') THEN
        ALTER TABLE public.loans ADD COLUMN deposit_amount DECIMAL(15,2) DEFAULT 0;
    END IF;
    
    -- 确保 loan_method 字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'loans' AND column_name = 'loan_method') THEN
        ALTER TABLE public.loans ADD COLUMN loan_method VARCHAR(20) DEFAULT 'scenario_a';
    END IF;
    
    -- 确保 issue_date 字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'loans' AND column_name = 'issue_date') THEN
        ALTER TABLE public.loans ADD COLUMN issue_date DATE DEFAULT CURRENT_DATE;
    END IF;
    
    -- 确保 due_date 字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'loans' AND column_name = 'due_date') THEN
        ALTER TABLE public.loans ADD COLUMN due_date DATE;
    END IF;
    
    -- 确保 notes 字段存在  
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'loans' AND column_name = 'notes') THEN
        ALTER TABLE public.loans ADD COLUMN notes TEXT;
    END IF;
    
    -- 删除旧的 loan_method 约束（如果存在）
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE table_name = 'loans' 
               AND constraint_name = 'loans_loan_method_check') THEN
        ALTER TABLE public.loans DROP CONSTRAINT loans_loan_method_check;
    END IF;
    
    -- 现在安全地进行数据同步
    -- 同步 collateral_amount 到 deposit_amount
    UPDATE public.loans SET deposit_amount = collateral_amount WHERE deposit_amount = 0 AND collateral_amount > 0;
    
    -- 同步贷款类型术语（现在没有约束限制）
    UPDATE public.loans SET loan_method = CASE 
        WHEN loan_type = 'type_a' THEN 'scenario_a'
        WHEN loan_type = 'type_b' THEN 'scenario_b'
        WHEN loan_method = 'mode1' THEN 'scenario_a'
        WHEN loan_method = 'mode2' THEN 'scenario_b'
        WHEN loan_method IS NULL THEN 'scenario_a'
        ELSE loan_method
    END;
    
    -- 添加新的 loan_method 约束
    ALTER TABLE public.loans 
    ADD CONSTRAINT loans_loan_method_check 
    CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c'));
    
    -- 设置默认日期（确保字段存在后再更新）
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'loans' AND column_name = 'issue_date') THEN
        UPDATE public.loans SET issue_date = disbursement_date WHERE issue_date IS NULL AND disbursement_date IS NOT NULL;
        UPDATE public.loans SET issue_date = CURRENT_DATE WHERE issue_date IS NULL;
    END IF;
    
    -- 设置到期日期
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'loans' AND column_name = 'due_date') THEN
        UPDATE public.loans SET due_date = disbursement_date + INTERVAL '1 day' * cycle_days WHERE due_date IS NULL;
    END IF;
END $$;

-- 同步合同模板字段
DO $$
BEGIN
    -- 确保 template_name 字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'contract_templates' AND column_name = 'template_name') THEN
        ALTER TABLE public.contract_templates ADD COLUMN template_name VARCHAR(100);
    END IF;
    
    -- 确保 template_content 字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'contract_templates' AND column_name = 'template_content') THEN
        ALTER TABLE public.contract_templates ADD COLUMN template_content TEXT;
    END IF;
    
    -- 先删除旧的约束（如果存在）
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE table_name = 'contract_templates' 
               AND constraint_name = 'contract_templates_loan_type_check') THEN
        ALTER TABLE public.contract_templates DROP CONSTRAINT contract_templates_loan_type_check;
    END IF;
    
    -- 同步模板字段
    UPDATE public.contract_templates SET template_name = name WHERE template_name IS NULL;
    UPDATE public.contract_templates SET template_content = content WHERE template_content IS NULL;
    UPDATE public.contract_templates SET name = template_name WHERE name IS NULL;
    UPDATE public.contract_templates SET content = template_content WHERE content IS NULL;
    
    -- 更新贷款类型术语（现在没有约束限制）
    UPDATE public.contract_templates SET loan_type = CASE 
        WHEN loan_type = 'type_a' THEN 'scenario_a'
        WHEN loan_type = 'type_b' THEN 'scenario_b'
        WHEN loan_type IS NULL THEN 'scenario_a'
        ELSE 'scenario_a'
    END;
    
    -- 添加新的约束
    ALTER TABLE public.contract_templates 
    ADD CONSTRAINT contract_templates_loan_type_check 
    CHECK (loan_type IN ('scenario_a', 'scenario_b', 'scenario_c'));
    
    -- 确保必要字段不为空
    UPDATE public.contract_templates SET template_name = COALESCE(name, '默认模板') WHERE template_name IS NULL;
    UPDATE public.contract_templates SET template_content = COALESCE(content, '默认内容') WHERE template_content IS NULL;
END $$;

-- 为新添加的字段设置非空约束（在数据同步后）
DO $$
BEGIN
    -- 设置 template_name 非空约束
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'contract_templates' AND column_name = 'template_name' AND is_nullable = 'YES') THEN
        ALTER TABLE public.contract_templates ALTER COLUMN template_name SET NOT NULL;
    END IF;
    
    -- 设置 template_content 非空约束
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'contract_templates' AND column_name = 'template_content' AND is_nullable = 'YES') THEN
        ALTER TABLE public.contract_templates ALTER COLUMN template_content SET NOT NULL;
    END IF;
END $$;

-- =========================================================================
-- 第三部分：业务逻辑函数
-- =========================================================================

-- 客户编号自动生成函数（支持UUID主键）
CREATE OR REPLACE FUNCTION generate_customer_number()
RETURNS TRIGGER AS $$
DECLARE
    prefix TEXT;
    next_number INTEGER;
    formatted_number TEXT;
BEGIN
    -- 检查是否已经有编号
    IF NEW.customer_number IS NOT NULL AND NEW.customer_number != '' THEN
        RETURN NEW;
    END IF;
    
    -- 从客户代号中提取前缀（前2位）
    prefix := UPPER(LEFT(NEW.customer_code, 2));
    
    -- 获取下一个编号
    SELECT COALESCE(MAX(CAST(SUBSTRING(customer_number FROM '[0-9]+$') AS INTEGER)), 0) + 1
    INTO next_number
    FROM public.customers
    WHERE customer_number LIKE prefix || '%';
    
    -- 格式化编号
    formatted_number := prefix || ' ' || LPAD(next_number::TEXT, 3, '0');
    NEW.customer_number := formatted_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 贷款计算函数（支持三种场景）
-- 先删除可能存在的旧函数
DROP FUNCTION IF EXISTS calculate_actual_amount(DECIMAL, DECIMAL, DECIMAL, INTEGER, VARCHAR);
DROP FUNCTION IF EXISTS calculate_actual_amount(DECIMAL, DECIMAL, DECIMAL, INTEGER);
DROP FUNCTION IF EXISTS calculate_actual_amount(DECIMAL, DECIMAL, DECIMAL);

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
    interest_amount := p_loan_amount * (p_interest_rate / 100);
    
    CASE p_loan_method
        WHEN 'scenario_a' THEN
            -- 场景A：利息+押金
            actual_amount := p_loan_amount - interest_amount - p_deposit_amount;
        WHEN 'scenario_b' THEN
            -- 场景B：只收利息
            actual_amount := p_loan_amount - interest_amount;
        WHEN 'scenario_c' THEN
            -- 场景C：只收押金
            actual_amount := p_loan_amount - p_deposit_amount;
        ELSE
            actual_amount := p_loan_amount - interest_amount - p_deposit_amount;
    END CASE;
    
    RETURN GREATEST(actual_amount, 0);
END;
$$ LANGUAGE plpgsql;

-- 客户贷款数据同步函数
-- 先删除可能存在的旧函数
DROP FUNCTION IF EXISTS sync_customer_loan_data();

CREATE OR REPLACE FUNCTION sync_customer_loan_data()
RETURNS void AS $$
DECLARE
    loan_record RECORD;
BEGIN
    FOR loan_record IN 
        SELECT DISTINCT ON (customer_id) 
            customer_id, loan_amount, interest_rate, loan_method,
            deposit_amount, actual_amount, cycle_days
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
            suggested_payment = CASE 
                WHEN loan_record.cycle_days > 0 THEN 
                    (loan_record.loan_amount / GREATEST(loan_record.cycle_days / 30.0, 1))
                ELSE loan_record.loan_amount / 10
            END,
            total_repayment = loan_record.loan_amount + (loan_record.loan_amount * loan_record.interest_rate / 100),
            periods = GREATEST(loan_record.cycle_days / 30, 1),
            principal_rate_per_period = 10.0,
            number_of_periods = GREATEST(loan_record.cycle_days / 30, 1)
        WHERE id = loan_record.customer_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =========================================================================
-- 第四部分：触发器设置
-- =========================================================================

-- 时间戳更新函数
-- 先删除所有依赖的触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_customers_updated_at ON public.customers;
DROP TRIGGER IF EXISTS update_loans_updated_at ON public.loans;
DROP TRIGGER IF EXISTS update_system_settings_updated_at ON public.system_settings;
DROP TRIGGER IF EXISTS update_contract_templates_updated_at ON public.contract_templates;
DROP TRIGGER IF EXISTS update_monthly_losses_updated_at ON public.monthly_losses;

-- 现在可以安全删除函数
DROP FUNCTION IF EXISTS update_updated_at_column();

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 贷款自动计算触发器
-- 先删除可能存在的触发器
DROP TRIGGER IF EXISTS trigger_auto_calculate_loan ON public.loans;

-- 删除可能存在的旧函数
DROP FUNCTION IF EXISTS auto_calculate_loan_details();

CREATE OR REPLACE FUNCTION auto_calculate_loan_details()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.loan_method IS NULL THEN
        NEW.loan_method := 'scenario_a';
    END IF;
    
    IF NEW.deposit_amount IS NULL THEN
        NEW.deposit_amount := COALESCE(NEW.collateral_amount, 0);
    END IF;
    
    NEW.actual_amount := calculate_actual_amount(
        NEW.loan_amount, NEW.interest_rate, NEW.deposit_amount,
        NEW.cycle_days, NEW.loan_method
    );
    
    NEW.remaining_principal := NEW.loan_amount;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建所有触发器
DROP TRIGGER IF EXISTS trigger_generate_customer_number ON public.customers;
CREATE TRIGGER trigger_generate_customer_number
    BEFORE INSERT ON public.customers
    FOR EACH ROW EXECUTE FUNCTION generate_customer_number();

DROP TRIGGER IF EXISTS trigger_auto_calculate_loan ON public.loans;
CREATE TRIGGER trigger_auto_calculate_loan
    BEFORE INSERT OR UPDATE ON public.loans
    FOR EACH ROW EXECUTE FUNCTION auto_calculate_loan_details();

-- 时间戳触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON public.loans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON public.system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_contract_templates_updated_at BEFORE UPDATE ON public.contract_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_monthly_losses_updated_at BEFORE UPDATE ON public.monthly_losses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =========================================================================
-- 第五部分：权限和安全设置
-- =========================================================================

-- 启用行级安全
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repayments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.overdue_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contract_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_losses ENABLE ROW LEVEL SECURITY;

-- 创建基础安全策略
-- 先删除可能存在的策略，然后重新创建
DROP POLICY IF EXISTS "Users can view all users" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view all customers" ON public.customers;
DROP POLICY IF EXISTS "Users can insert customers" ON public.customers;
DROP POLICY IF EXISTS "Users can update customers" ON public.customers;
DROP POLICY IF EXISTS "Users can view all loans" ON public.loans;
DROP POLICY IF EXISTS "Users can insert loans" ON public.loans;
DROP POLICY IF EXISTS "Users can update loans" ON public.loans;
DROP POLICY IF EXISTS "Users can view all repayments" ON public.repayments;
DROP POLICY IF EXISTS "Users can insert repayments" ON public.repayments;

-- 重新创建策略
CREATE POLICY "Users can view all users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view all customers" ON public.customers FOR SELECT USING (true);
CREATE POLICY "Users can insert customers" ON public.customers FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update customers" ON public.customers FOR UPDATE USING (true);
CREATE POLICY "Users can view all loans" ON public.loans FOR SELECT USING (true);
CREATE POLICY "Users can insert loans" ON public.loans FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update loans" ON public.loans FOR UPDATE USING (true);
CREATE POLICY "Users can view all repayments" ON public.repayments FOR SELECT USING (true);
CREATE POLICY "Users can insert repayments" ON public.repayments FOR INSERT WITH CHECK (true);

-- =========================================================================
-- 第六部分：索引优化和默认数据
-- =========================================================================

-- 创建性能索引
CREATE INDEX IF NOT EXISTS idx_customers_code ON public.customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_number ON public.customers(customer_number);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_loan_method ON public.customers(loan_method);
CREATE INDEX IF NOT EXISTS idx_loans_customer_id ON public.loans(customer_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON public.loans(status);
CREATE INDEX IF NOT EXISTS idx_repayments_loan_id ON public.repayments(loan_id);
CREATE INDEX IF NOT EXISTS idx_repayments_customer_id ON public.repayments(customer_id);

-- 确保系统设置表字段存在
DO $$
BEGIN
    -- 确保 setting_type 字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'system_settings' AND column_name = 'setting_type') THEN
        ALTER TABLE public.system_settings ADD COLUMN setting_type VARCHAR(20) DEFAULT 'string';
        -- 添加约束
        ALTER TABLE public.system_settings 
        ADD CONSTRAINT system_settings_setting_type_check 
        CHECK (setting_type IN ('string', 'number', 'boolean', 'json'));
    END IF;
    
    -- 确保 description 字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'system_settings' AND column_name = 'description') THEN
        ALTER TABLE public.system_settings ADD COLUMN description TEXT;
    END IF;
END $$;

-- 插入默认系统设置
INSERT INTO public.system_settings (setting_key, setting_value, setting_type, description) VALUES
('default_penalty_rate', '0.05', 'number', '默认日罚金利率 (5%)'),
('company_name', '贷款管理公司', 'string', '公司名称'),
('max_loan_amount', '1000000', 'number', '最大贷款金额'),
('system_version', '2.0', 'string', '系统版本'),
('terminology_unified', 'true', 'boolean', '术语已统一'),
('database_unified_at', NOW()::text, 'string', '数据库统一时间')
ON CONFLICT (setting_key) DO UPDATE SET 
    setting_value = EXCLUDED.setting_value, updated_at = NOW();

-- 插入默认合同模板
INSERT INTO public.contract_templates (name, template_name, content, template_content, loan_type, is_active) VALUES
('场景A贷款合同', '利息+押金贷款合同', 
 '客户：{customer_name}，身份证：{id_number}，贷款：{loan_amount}，利息：{interest_rate}%，押金：{deposit_amount}，到手：{received_amount}',
 '客户：{customer_name}，身份证：{id_number}，贷款：{loan_amount}，利息：{interest_rate}%，押金：{deposit_amount}，到手：{received_amount}',
 'scenario_a', true),
('场景B贷款合同', '只收利息贷款合同',
 '客户：{customer_name}，身份证：{id_number}，贷款：{loan_amount}，利息：{interest_rate}%，到手：{received_amount}',
 '客户：{customer_name}，身份证：{id_number}，贷款：{loan_amount}，利息：{interest_rate}%，到手：{received_amount}',
 'scenario_b', true),
('场景C贷款合同', '只收押金贷款合同',
 '客户：{customer_name}，身份证：{id_number}，贷款：{loan_amount}，押金：{deposit_amount}，到手：{received_amount}',
 '客户：{customer_name}，身份证：{id_number}，贷款：{loan_amount}，押金：{deposit_amount}，到手：{received_amount}',
 'scenario_c', true)
ON CONFLICT DO NOTHING;

-- =========================================================================
-- 第七部分：执行同步和验证
-- =========================================================================

-- 执行数据同步
SELECT sync_customer_loan_data();

-- 创建验证视图
CREATE OR REPLACE VIEW public.system_status_report AS
SELECT 'customers' as table_name, 'loan_method' as field, loan_method as value, COUNT(*) as count
FROM public.customers WHERE loan_method IS NOT NULL GROUP BY loan_method
UNION ALL
SELECT 'customers' as table_name, 'status' as field, status as value, COUNT(*) as count
FROM public.customers GROUP BY status
UNION ALL
SELECT 'repayments' as table_name, 'repayment_type' as field, repayment_type as value, COUNT(*) as count
FROM public.repayments GROUP BY repayment_type
ORDER BY table_name, field, value;

-- 完成报告
SELECT '🎉 贷款管理系统数据库部署完成！' as status, NOW() as completed_at;
SELECT '=== 系统状态报告 ===' as report_section;
SELECT * FROM public.system_status_report;

-- 显示关键配置
SELECT '=== 系统配置验证 ===' as config_section;
SELECT setting_key, setting_value, description 
FROM public.system_settings 
WHERE setting_key IN ('system_version', 'terminology_unified', 'database_unified_at')
ORDER BY setting_key;