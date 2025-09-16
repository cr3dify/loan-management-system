-- =========================================================================
-- Phase 2: 费用管理系统数据库表创建脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 费用类型表
CREATE TABLE IF NOT EXISTS public.expense_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 费用表
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.users(id),
    expense_type_id UUID NOT NULL REFERENCES public.expense_types(id),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    receipt_url TEXT,
    approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    approved_by UUID REFERENCES public.users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 员工盈亏表
CREATE TABLE IF NOT EXISTS public.employee_profits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.users(id),
    period_year INTEGER NOT NULL,
    period_month INTEGER NOT NULL CHECK (period_month >= 1 AND period_month <= 12),
    total_loans DECIMAL(15,2) DEFAULT 0, -- 放款总额
    total_repayments DECIMAL(15,2) DEFAULT 0, -- 回款总额
    total_expenses DECIMAL(15,2) DEFAULT 0, -- 总费用
    net_profit DECIMAL(15,2) DEFAULT 0, -- 净利润
    roi_percentage DECIMAL(5,2) DEFAULT 0, -- ROI百分比
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(employee_id, period_year, period_month)
);

-- 4. 审批记录表
CREATE TABLE IF NOT EXISTS public.approval_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_type VARCHAR(50) NOT NULL CHECK (record_type IN ('customer', 'expense', 'repayment')),
    record_id UUID NOT NULL,
    approver_id UUID NOT NULL REFERENCES public.users(id),
    approval_status VARCHAR(20) NOT NULL CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    approval_level INTEGER NOT NULL DEFAULT 1, -- 审批级别 1=第一级, 2=第二级
    comments TEXT,
    approved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 插入默认费用类型
INSERT INTO public.expense_types (name, description) VALUES
('交通费', '员工外出交通费用'),
('文书费', '合同、文件处理费用'),
('客户招待', '客户接待和招待费用'),
('坏账补贴', '坏账损失补贴'),
('办公用品', '办公用品采购费用'),
('通讯费', '电话、网络等通讯费用'),
('其他', '其他业务相关费用')
ON CONFLICT (name) DO NOTHING;

-- 6. 创建索引
CREATE INDEX IF NOT EXISTS idx_expenses_employee_id ON public.expenses(employee_id);
CREATE INDEX IF NOT EXISTS idx_expenses_approval_status ON public.expenses(approval_status);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON public.expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_employee_profits_employee_id ON public.employee_profits(employee_id);
CREATE INDEX IF NOT EXISTS idx_employee_profits_period ON public.employee_profits(period_year, period_month);
CREATE INDEX IF NOT EXISTS idx_approval_records_record ON public.approval_records(record_type, record_id);

-- 7. 创建触发器函数
CREATE OR REPLACE FUNCTION public.update_expense_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. 创建触发器
CREATE TRIGGER trigger_update_expenses_updated_at
    BEFORE UPDATE ON public.expenses
    FOR EACH ROW
    EXECUTE FUNCTION public.update_expense_updated_at();

CREATE TRIGGER trigger_update_expense_types_updated_at
    BEFORE UPDATE ON public.expense_types
    FOR EACH ROW
    EXECUTE FUNCTION public.update_expense_updated_at();

CREATE TRIGGER trigger_update_employee_profits_updated_at
    BEFORE UPDATE ON public.employee_profits
    FOR EACH ROW
    EXECUTE FUNCTION public.update_expense_updated_at();

-- 9. 启用行级安全
ALTER TABLE public.expense_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_profits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approval_records ENABLE ROW LEVEL SECURITY;

-- 10. 创建RLS策略
-- 费用类型：所有员工可查看
CREATE POLICY "Anyone can view expense types" ON public.expense_types
    FOR SELECT USING (true);

-- 费用：员工只能查看自己的，管理员/秘书可查看所有
CREATE POLICY "Users can view own expenses" ON public.expenses
    FOR SELECT USING (
        employee_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND (
                auth.users.app_metadata->>'role' IN ('admin', 'secretary', 'manager', 'super_admin')
                OR auth.users.user_metadata->>'role' IN ('admin', 'secretary', 'manager', 'super_admin')
            )
        )
    );

-- 费用：员工可以创建自己的费用
CREATE POLICY "Users can create own expenses" ON public.expenses
    FOR INSERT WITH CHECK (employee_id = auth.uid());

-- 费用：管理员/秘书可以更新费用
CREATE POLICY "Admins can update expenses" ON public.expenses
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND (
                auth.users.app_metadata->>'role' IN ('admin', 'secretary', 'manager', 'super_admin')
                OR auth.users.user_metadata->>'role' IN ('admin', 'secretary', 'manager', 'super_admin')
            )
        )
    );

-- 员工盈亏：员工只能查看自己的，管理员可查看所有
CREATE POLICY "Users can view own profits" ON public.employee_profits
    FOR SELECT USING (
        employee_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND (
                auth.users.app_metadata->>'role' IN ('admin', 'manager', 'super_admin')
                OR auth.users.user_metadata->>'role' IN ('admin', 'manager', 'super_admin')
            )
        )
    );

-- 审批记录：管理员/秘书可查看和创建
CREATE POLICY "Admins can manage approval records" ON public.approval_records
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid() 
            AND (
                auth.users.app_metadata->>'role' IN ('admin', 'secretary', 'manager', 'super_admin')
                OR auth.users.user_metadata->>'role' IN ('admin', 'secretary', 'manager', 'super_admin')
            )
        )
    );

-- 11. 创建计算员工盈亏的RPC函数
CREATE OR REPLACE FUNCTION public.calculate_employee_profit(
    p_employee_id UUID,
    p_year INTEGER,
    p_month INTEGER
) RETURNS JSON AS $$
DECLARE
    total_loans DECIMAL(15,2) := 0;
    total_repayments DECIMAL(15,2) := 0;
    total_expenses DECIMAL(15,2) := 0;
    net_profit DECIMAL(15,2) := 0;
    roi_percentage DECIMAL(5,2) := 0;
    result JSON;
BEGIN
    -- 计算放款总额（该员工创建的客户）
    SELECT COALESCE(SUM(loan_amount), 0)
    INTO total_loans
    FROM public.customers
    WHERE created_by = p_employee_id
    AND EXTRACT(YEAR FROM created_at) = p_year
    AND EXTRACT(MONTH FROM created_at) = p_month;

    -- 计算回款总额（该员工的客户还款）
    SELECT COALESCE(SUM(r.amount), 0)
    INTO total_repayments
    FROM public.repayments r
    JOIN public.customers c ON r.customer_id = c.id
    WHERE c.created_by = p_employee_id
    AND EXTRACT(YEAR FROM r.payment_date) = p_year
    AND EXTRACT(MONTH FROM r.payment_date) = p_month;

    -- 计算总费用（该员工已批准的费用）
    SELECT COALESCE(SUM(amount), 0)
    INTO total_expenses
    FROM public.expenses
    WHERE employee_id = p_employee_id
    AND approval_status = 'approved'
    AND EXTRACT(YEAR FROM expense_date) = p_year
    AND EXTRACT(MONTH FROM expense_date) = p_month;

    -- 计算净利润
    net_profit := total_repayments - total_expenses;

    -- 计算ROI
    IF total_loans > 0 THEN
        roi_percentage := (net_profit / total_loans) * 100;
    END IF;

    -- 更新或插入员工盈亏记录
    INSERT INTO public.employee_profits (
        employee_id, period_year, period_month,
        total_loans, total_repayments, total_expenses,
        net_profit, roi_percentage
    ) VALUES (
        p_employee_id, p_year, p_month,
        total_loans, total_repayments, total_expenses,
        net_profit, roi_percentage
    )
    ON CONFLICT (employee_id, period_year, period_month)
    DO UPDATE SET
        total_loans = EXCLUDED.total_loans,
        total_repayments = EXCLUDED.total_repayments,
        total_expenses = EXCLUDED.total_expenses,
        net_profit = EXCLUDED.net_profit,
        roi_percentage = EXCLUDED.roi_percentage,
        updated_at = NOW();

    -- 返回结果
    result := json_build_object(
        'employee_id', p_employee_id,
        'period_year', p_year,
        'period_month', p_month,
        'total_loans', total_loans,
        'total_repayments', total_repayments,
        'total_expenses', total_expenses,
        'net_profit', net_profit,
        'roi_percentage', roi_percentage
    );

    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

SELECT '🎉 Phase 2 费用管理系统数据库创建完成！' as status;
