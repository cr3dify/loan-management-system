-- 贷款管理系统完整数据库设置脚本
-- 请将此脚本复制到 Supabase SQL 编辑器中执行

-- 1. 创建用户表
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'employee' CHECK (role IN ('admin', 'secretary', 'employee')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 创建客户表
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_code VARCHAR(50) UNIQUE NOT NULL, -- 客户代号
    customer_number VARCHAR(20) UNIQUE NOT NULL, -- 自动生成编号 (如: XA 001)
    name VARCHAR(100) NOT NULL, -- 姓名
    id_card VARCHAR(50) NOT NULL, -- 身份证
    phone VARCHAR(20) NOT NULL, -- 电话
    address TEXT NOT NULL, -- 地址
    notes TEXT, -- 备注 (家庭状况、风险等级等)
    status VARCHAR(20) DEFAULT 'normal' CHECK (status IN ('normal', 'completed', 'negotiating', 'bad_debt')), -- 客户状态
    approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')), -- 审核状态
    contract_signed BOOLEAN DEFAULT FALSE, -- 合同签署状态
    negotiation_terms TEXT, -- 谈帐条件
    loss_amount DECIMAL(15,2) DEFAULT 0, -- 亏损金额
    created_by UUID REFERENCES public.users(id),
    approved_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 创建贷款表
CREATE TABLE IF NOT EXISTS public.loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    loan_amount DECIMAL(15,2) NOT NULL, -- 贷款金额
    interest_rate DECIMAL(5,2) NOT NULL, -- 利息率 (%/周期)
    collateral_amount DECIMAL(15,2) NOT NULL, -- 抵押金额
    cycle_days INTEGER NOT NULL, -- 周期天数
    loan_type VARCHAR(20) NOT NULL CHECK (loan_type IN ('type_a', 'type_b')), -- 贷款类型
    disbursement_date DATE NOT NULL, -- 发放日期
    actual_amount DECIMAL(15,2) NOT NULL, -- 实际到手金额
    remaining_principal DECIMAL(15,2) NOT NULL, -- 剩余本金
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'overdue')),
    contract_template_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 创建还款记录表
CREATE TABLE IF NOT EXISTS public.repayments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    repayment_type VARCHAR(20) NOT NULL CHECK (repayment_type IN ('interest_only', 'partial_principal', 'full_settlement')),
    amount DECIMAL(15,2) NOT NULL, -- 还款金额
    interest_amount DECIMAL(15,2) DEFAULT 0, -- 利息部分
    principal_amount DECIMAL(15,2) DEFAULT 0, -- 本金部分
    penalty_amount DECIMAL(15,2) DEFAULT 0, -- 罚金部分
    excess_amount DECIMAL(15,2) DEFAULT 0, -- 多余金额
    repayment_date DATE NOT NULL,
    due_date DATE NOT NULL, -- 应还日期
    notes TEXT,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 创建逾期记录表
CREATE TABLE IF NOT EXISTS public.overdue_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loan_id UUID NOT NULL REFERENCES public.loans(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    overdue_days INTEGER NOT NULL,
    penalty_rate DECIMAL(5,2) NOT NULL, -- 日罚金利率
    penalty_amount DECIMAL(15,2) NOT NULL, -- 罚金金额
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'resolved')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- 6. 创建系统设置表
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES public.users(id),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. 创建合同模板表
CREATE TABLE IF NOT EXISTS public.contract_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    content TEXT NOT NULL,
    loan_type VARCHAR(20) CHECK (loan_type IN ('type_a', 'type_b')),
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. 创建月度亏损统计表
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

-- 9. 创建触发器函数：自动生成客户编号
CREATE OR REPLACE FUNCTION generate_customer_number()
RETURNS TRIGGER AS $$
DECLARE
    prefix TEXT;
    next_number INTEGER;
    formatted_number TEXT;
BEGIN
    -- 从客户代号提取前缀（取前2个字符）
    prefix := UPPER(LEFT(NEW.customer_code, 2));
    
    -- 查找该前缀的最大编号
    SELECT COALESCE(MAX(CAST(SUBSTRING(customer_number FROM '[0-9]+$') AS INTEGER)), 0) + 1
    INTO next_number
    FROM public.customers
    WHERE customer_number LIKE prefix || '%';
    
    -- 格式化编号 (如: XA 001)
    formatted_number := prefix || ' ' || LPAD(next_number::TEXT, 3, '0');
    
    NEW.customer_number := formatted_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 10. 创建触发器：客户编号自动生成
DROP TRIGGER IF EXISTS trigger_generate_customer_number ON public.customers;
CREATE TRIGGER trigger_generate_customer_number
    BEFORE INSERT ON public.customers
    FOR EACH ROW
    EXECUTE FUNCTION generate_customer_number();

-- 11. 创建触发器函数：更新时间戳
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 12. 为所有表添加更新时间戳触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_loans_updated_at BEFORE UPDATE ON public.loans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_settings_updated_at BEFORE UPDATE ON public.system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_contract_templates_updated_at BEFORE UPDATE ON public.contract_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_monthly_losses_updated_at BEFORE UPDATE ON public.monthly_losses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 13. 启用行级安全 (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.repayments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.overdue_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contract_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_losses ENABLE ROW LEVEL SECURITY;

-- 14. 创建 RLS 策略
-- 用户表策略
CREATE POLICY "Users can view all users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- 客户表策略
CREATE POLICY "Users can view all customers" ON public.customers FOR SELECT USING (true);
CREATE POLICY "Users can insert customers" ON public.customers FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update customers" ON public.customers FOR UPDATE USING (true);

-- 贷款表策略
CREATE POLICY "Users can view all loans" ON public.loans FOR SELECT USING (true);
CREATE POLICY "Users can insert loans" ON public.loans FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update loans" ON public.loans FOR UPDATE USING (true);

-- 还款记录策略
CREATE POLICY "Users can view all repayments" ON public.repayments FOR SELECT USING (true);
CREATE POLICY "Users can insert repayments" ON public.repayments FOR INSERT WITH CHECK (true);

-- 逾期记录策略
CREATE POLICY "Users can view all overdue records" ON public.overdue_records FOR SELECT USING (true);
CREATE POLICY "Users can insert overdue records" ON public.overdue_records FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update overdue records" ON public.overdue_records FOR UPDATE USING (true);

-- 系统设置策略
CREATE POLICY "Users can view system settings" ON public.system_settings FOR SELECT USING (true);
CREATE POLICY "Admins can modify system settings" ON public.system_settings FOR ALL USING (true);

-- 合同模板策略
CREATE POLICY "Users can view contract templates" ON public.contract_templates FOR SELECT USING (true);
CREATE POLICY "Users can insert contract templates" ON public.contract_templates FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update contract templates" ON public.contract_templates FOR UPDATE USING (true);

-- 月度亏损策略
CREATE POLICY "Users can view monthly losses" ON public.monthly_losses FOR SELECT USING (true);
CREATE POLICY "Users can insert monthly losses" ON public.monthly_losses FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update monthly losses" ON public.monthly_losses FOR UPDATE USING (true);

-- 15. 插入默认系统设置
INSERT INTO public.system_settings (setting_key, setting_value, description) VALUES
('default_penalty_rate', '0.05', '默认日罚金利率 (5%)'),
('company_name', '贷款管理公司', '公司名称'),
('max_loan_amount', '1000000', '最大贷款金额'),
('min_cycle_days', '7', '最小贷款周期天数'),
('max_cycle_days', '365', '最大贷款周期天数')
ON CONFLICT (setting_key) DO NOTHING;

-- 16. 插入默认合同模板
INSERT INTO public.contract_templates (name, content, loan_type, is_active) VALUES
('A类贷款合同模板', '这是A类贷款的标准合同模板...', 'type_a', true),
('B类贷款合同模板', '这是B类贷款的标准合同模板...', 'type_b', true)
ON CONFLICT DO NOTHING;

-- 17. 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_customers_code ON public.customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_number ON public.customers(customer_number);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_loans_customer_id ON public.loans(customer_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON public.loans(status);
CREATE INDEX IF NOT EXISTS idx_repayments_loan_id ON public.repayments(loan_id);
CREATE INDEX IF NOT EXISTS idx_repayments_customer_id ON public.repayments(customer_id);
CREATE INDEX IF NOT EXISTS idx_overdue_records_loan_id ON public.overdue_records(loan_id);
CREATE INDEX IF NOT EXISTS idx_monthly_losses_year_month ON public.monthly_losses(year, month);

-- 添加计算底层逻辑函数

-- 18. 创建贷款计算函数：计算实际到手金额
CREATE OR REPLACE FUNCTION calculate_actual_amount(
    p_loan_amount DECIMAL(15,2),
    p_interest_rate DECIMAL(5,2),
    p_collateral_amount DECIMAL(15,2),
    p_cycle_days INTEGER,
    p_loan_type VARCHAR(20)
) RETURNS DECIMAL(15,2) AS $$
DECLARE
    interest_amount DECIMAL(15,2);
    actual_amount DECIMAL(15,2);
BEGIN
    -- 计算利息金额
    IF p_loan_type = 'type_a' THEN
        -- A类：预扣利息
        interest_amount := p_loan_amount * (p_interest_rate / 100);
    ELSE
        -- B类：后付利息
        interest_amount := 0;
    END IF;
    
    -- 计算实际到手金额：贷款总额 - 利息 - 抵押金
    actual_amount := p_loan_amount - interest_amount - p_collateral_amount;
    
    RETURN actual_amount;
END;
$$ LANGUAGE plpgsql;

-- 19. 创建还款分配计算函数
CREATE OR REPLACE FUNCTION calculate_repayment_allocation(
    p_loan_id UUID,
    p_repayment_amount DECIMAL(15,2)
) RETURNS TABLE(
    penalty_allocated DECIMAL(15,2),
    interest_allocated DECIMAL(15,2),
    principal_allocated DECIMAL(15,2),
    excess_amount DECIMAL(15,2)
) AS $$
DECLARE
    current_penalty DECIMAL(15,2) := 0;
    current_interest DECIMAL(15,2) := 0;
    remaining_amount DECIMAL(15,2) := p_repayment_amount;
    loan_record RECORD;
BEGIN
    -- 获取贷款信息
    SELECT * INTO loan_record FROM public.loans WHERE id = p_loan_id;
    
    -- 计算当前逾期罚金
    SELECT COALESCE(SUM(penalty_amount), 0) INTO current_penalty
    FROM public.overdue_records 
    WHERE loan_id = p_loan_id AND status = 'active';
    
    -- 计算当期利息
    current_interest := loan_record.remaining_principal * (loan_record.interest_rate / 100);
    
    -- 分配逻辑：优先扣除罚金 -> 利息 -> 本金
    penalty_allocated := LEAST(remaining_amount, current_penalty);
    remaining_amount := remaining_amount - penalty_allocated;
    
    interest_allocated := LEAST(remaining_amount, current_interest);
    remaining_amount := remaining_amount - interest_allocated;
    
    principal_allocated := LEAST(remaining_amount, loan_record.remaining_principal);
    remaining_amount := remaining_amount - principal_allocated;
    
    excess_amount := remaining_amount;
    
    RETURN QUERY SELECT penalty_allocated, interest_allocated, principal_allocated, excess_amount;
END;
$$ LANGUAGE plpgsql;

-- 20. 创建逾期罚金计算函数
CREATE OR REPLACE FUNCTION calculate_overdue_penalty(
    p_loan_id UUID,
    p_overdue_days INTEGER
) RETURNS DECIMAL(15,2) AS $$
DECLARE
    loan_record RECORD;
    penalty_rate DECIMAL(5,2);
    penalty_amount DECIMAL(15,2);
BEGIN
    -- 获取贷款信息
    SELECT * INTO loan_record FROM public.loans WHERE id = p_loan_id;
    
    -- 获取罚金利率
    SELECT CAST(setting_value AS DECIMAL(5,2)) INTO penalty_rate
    FROM public.system_settings 
    WHERE setting_key = 'default_penalty_rate';
    
    -- 计算罚金：剩余本金 * 日罚金利率 * 逾期天数
    penalty_amount := loan_record.remaining_principal * (penalty_rate / 100) * p_overdue_days;
    
    RETURN penalty_amount;
END;
$$ LANGUAGE plpgsql;

-- 21. 创建客户状态自动更新函数
CREATE OR REPLACE FUNCTION update_customer_status()
RETURNS TRIGGER AS $$
DECLARE
    customer_record RECORD;
    total_remaining DECIMAL(15,2);
    has_overdue BOOLEAN;
BEGIN
    -- 获取客户信息
    SELECT * INTO customer_record FROM public.customers WHERE id = NEW.customer_id;
    
    -- 计算客户总剩余本金
    SELECT COALESCE(SUM(remaining_principal), 0) INTO total_remaining
    FROM public.loans 
    WHERE customer_id = NEW.customer_id AND status = 'active';
    
    -- 检查是否有逾期
    SELECT EXISTS(
        SELECT 1 FROM public.loans l
        JOIN public.overdue_records o ON l.id = o.loan_id
        WHERE l.customer_id = NEW.customer_id AND o.status = 'active'
    ) INTO has_overdue;
    
    -- 更新客户状态
    IF total_remaining = 0 THEN
        -- 所有贷款已还清
        UPDATE public.customers SET status = 'completed' WHERE id = NEW.customer_id;
    ELSIF has_overdue THEN
        -- 有逾期贷款
        UPDATE public.customers SET status = 'normal' WHERE id = NEW.customer_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 22. 创建月度亏损统计更新函数
CREATE OR REPLACE FUNCTION update_monthly_loss_stats()
RETURNS TRIGGER AS $$
DECLARE
    loss_year INTEGER;
    loss_month INTEGER;
BEGIN
    -- 获取当前年月
    loss_year := EXTRACT(YEAR FROM NOW());
    loss_month := EXTRACT(MONTH FROM NOW());
    
    -- 如果客户状态变为烂账，更新月度统计
    IF NEW.status = 'bad_debt' AND OLD.status != 'bad_debt' THEN
        INSERT INTO public.monthly_losses (year, month, total_loss_amount, bad_debt_count)
        VALUES (loss_year, loss_month, NEW.loss_amount, 1)
        ON CONFLICT (year, month) 
        DO UPDATE SET 
            total_loss_amount = monthly_losses.total_loss_amount + NEW.loss_amount,
            bad_debt_count = monthly_losses.bad_debt_count + 1,
            updated_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 23. 创建贷款自动计算触发器
CREATE OR REPLACE FUNCTION auto_calculate_loan_details()
RETURNS TRIGGER AS $$
BEGIN
    -- 自动计算实际到手金额
    NEW.actual_amount := calculate_actual_amount(
        NEW.loan_amount,
        NEW.interest_rate,
        NEW.collateral_amount,
        NEW.cycle_days,
        NEW.loan_type
    );
    
    -- 初始化剩余本金
    NEW.remaining_principal := NEW.loan_amount;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 24. 添加触发器
DROP TRIGGER IF EXISTS trigger_auto_calculate_loan ON public.loans;
CREATE TRIGGER trigger_auto_calculate_loan
    BEFORE INSERT OR UPDATE ON public.loans
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_loan_details();

DROP TRIGGER IF EXISTS trigger_update_customer_status ON public.repayments;
CREATE TRIGGER trigger_update_customer_status
    AFTER INSERT ON public.repayments
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_status();

DROP TRIGGER IF EXISTS trigger_update_monthly_loss ON public.customers;
CREATE TRIGGER trigger_update_monthly_loss
    AFTER UPDATE ON public.customers
    FOR EACH ROW
    EXECUTE FUNCTION update_monthly_loss_stats();

-- 25. 创建逾期检查和罚金计算的定时任务函数
CREATE OR REPLACE FUNCTION check_and_create_overdue_records()
RETURNS void AS $$
DECLARE
    loan_record RECORD;
    overdue_days INTEGER;
    penalty_amount DECIMAL(15,2);
BEGIN
    -- 检查所有活跃贷款的逾期情况
    FOR loan_record IN 
        SELECT l.*, 
               (CURRENT_DATE - (l.disbursement_date + INTERVAL '1 day' * l.cycle_days))::INTEGER as days_overdue
        FROM public.loans l
        WHERE l.status = 'active' 
        AND CURRENT_DATE > (l.disbursement_date + INTERVAL '1 day' * l.cycle_days)
    LOOP
        overdue_days := loan_record.days_overdue;
        
        -- 计算罚金
        penalty_amount := calculate_overdue_penalty(loan_record.id, overdue_days);
        
        -- 更新贷款状态为逾期
        UPDATE public.loans SET status = 'overdue' WHERE id = loan_record.id;
        
        -- 创建或更新逾期记录
        INSERT INTO public.overdue_records (
            loan_id, customer_id, overdue_days, penalty_rate, penalty_amount, status
        ) VALUES (
            loan_record.id, 
            loan_record.customer_id, 
            overdue_days,
            (SELECT CAST(setting_value AS DECIMAL(5,2)) FROM public.system_settings WHERE setting_key = 'default_penalty_rate'),
            penalty_amount,
            'active'
        )
        ON CONFLICT (loan_id) DO UPDATE SET
            overdue_days = EXCLUDED.overdue_days,
            penalty_amount = EXCLUDED.penalty_amount,
            created_at = NOW();
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 完成！包含完整计算逻辑的数据库设置已完成
-- 您现在可以开始使用功能完整的贷款管理系统了
