-- =========================================================================
-- Phase 2 连接测试脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 检查表是否存在
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'expense_types' AND table_schema = 'public') THEN
        RAISE NOTICE '✅ expense_types 表存在';
    ELSE
        RAISE NOTICE '❌ expense_types 表不存在';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'expenses' AND table_schema = 'public') THEN
        RAISE NOTICE '✅ expenses 表存在';
    ELSE
        RAISE NOTICE '❌ expenses 表不存在';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employee_profits' AND table_schema = 'public') THEN
        RAISE NOTICE '✅ employee_profits 表存在';
    ELSE
        RAISE NOTICE '❌ employee_profits 表不存在';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'approval_records' AND table_schema = 'public') THEN
        RAISE NOTICE '✅ approval_records 表存在';
    ELSE
        RAISE NOTICE '❌ approval_records 表不存在';
    END IF;
END $$;

-- 2. 如果表不存在，创建它们
CREATE TABLE IF NOT EXISTS public.expense_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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

CREATE TABLE IF NOT EXISTS public.employee_profits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employee_id UUID NOT NULL REFERENCES public.users(id),
    period_year INTEGER NOT NULL,
    period_month INTEGER NOT NULL CHECK (period_month >= 1 AND period_month <= 12),
    total_loans DECIMAL(15,2) DEFAULT 0,
    total_repayments DECIMAL(15,2) DEFAULT 0,
    total_expenses DECIMAL(15,2) DEFAULT 0,
    net_profit DECIMAL(15,2) DEFAULT 0,
    roi_percentage DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(employee_id, period_year, period_month)
);

CREATE TABLE IF NOT EXISTS public.approval_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    record_type VARCHAR(50) NOT NULL CHECK (record_type IN ('customer', 'expense', 'repayment')),
    record_id UUID NOT NULL,
    approver_id UUID REFERENCES public.users(id),
    approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    approval_level INTEGER DEFAULT 1,
    comments TEXT,
    approved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 插入默认数据
INSERT INTO public.expense_types (name, description)
VALUES
    ('交通费', '员工外出交通费用'),
    ('文书费', '合同、文件处理费用'),
    ('客户招待', '客户接待和招待费用'),
    ('坏账补贴', '坏账损失补贴'),
    ('办公用品', '办公用品采购费用'),
    ('通讯费', '电话、网络等通讯费用'),
    ('其他', '其他业务相关费用')
ON CONFLICT (name) DO NOTHING;

-- 4. 设置 RLS 策略
ALTER TABLE public.expense_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_profits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.approval_records ENABLE ROW LEVEL SECURITY;

-- 费用类型：所有用户可查看
DROP POLICY IF EXISTS "Allow all users to view expense types" ON public.expense_types;
CREATE POLICY "Allow all users to view expense types" ON public.expense_types FOR SELECT USING (true);

-- 费用：员工可查看自己的，管理员可查看所有
DROP POLICY IF EXISTS "Employees can view their own expenses" ON public.expenses;
CREATE POLICY "Employees can view their own expenses" ON public.expenses FOR SELECT USING (
    employee_id = auth.uid() OR 
    (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin', 'secretary', 'manager')
);

-- 员工盈亏：员工可查看自己的，管理员可查看所有
DROP POLICY IF EXISTS "Employees can view their own profits" ON public.employee_profits;
CREATE POLICY "Employees can view their own profits" ON public.employee_profits FOR SELECT USING (
    employee_id = auth.uid() OR 
    (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin', 'manager')
);

-- 审批记录：相关用户可以查看
DROP POLICY IF EXISTS "Users can view relevant approval records" ON public.approval_records;
CREATE POLICY "Users can view relevant approval records" ON public.approval_records FOR SELECT USING (
    approver_id = auth.uid() OR
    (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin', 'secretary', 'manager')
);

-- 5. 测试查询
SELECT 'Phase 2 表创建完成！' as status;
SELECT COUNT(*) as expense_types_count FROM public.expense_types;
SELECT COUNT(*) as expenses_count FROM public.expenses;
