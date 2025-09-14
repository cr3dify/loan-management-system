-- 🚀 Supabase 前后端统一快速执行脚本
-- 请在 Supabase SQL Editor 中执行此脚本

-- ============================================
-- 第一步：备份数据（必须执行）
-- ============================================
CREATE TABLE customers_backup AS SELECT * FROM customers;
CREATE TABLE loans_backup AS SELECT * FROM loans;
CREATE TABLE repayments_backup AS SELECT * FROM repayments;
SELECT '✅ 数据备份完成' as step_1;

-- ============================================
-- 第二步：修复 customers 表
-- ============================================
-- 数据迁移
UPDATE customers SET full_name = name WHERE full_name IS NULL OR full_name = '';
UPDATE customers SET id_number = id_card WHERE id_number IS NULL OR id_number = '';

-- 移除重复字段
ALTER TABLE customers DROP COLUMN IF EXISTS name;
ALTER TABLE customers DROP COLUMN IF EXISTS id_card;

-- 添加缺失字段
ALTER TABLE customers ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES auth.users(id);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS contract_signed_at TIMESTAMPTZ;

-- 修改约束
ALTER TABLE customers ALTER COLUMN customer_number DROP NOT NULL;
SELECT '✅ customers 表修复完成' as step_2;

-- ============================================
-- 第三步：重建 loans 表
-- ============================================
DROP TABLE IF EXISTS loans CASCADE;

CREATE TABLE loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    loan_amount DECIMAL(15,2) NOT NULL CHECK (loan_amount > 0),
    interest_rate DECIMAL(5,2) NOT NULL CHECK (interest_rate >= 0),
    loan_method TEXT NOT NULL CHECK (loan_method IN ('scenario_a', 'scenario_b', 'scenario_c')),
    deposit_amount DECIMAL(15,2) DEFAULT 0 CHECK (deposit_amount >= 0),
    total_repayment DECIMAL(15,2) NOT NULL CHECK (total_repayment > 0),
    periods INTEGER NOT NULL CHECK (periods > 0),
    cycle_days INTEGER NOT NULL DEFAULT 30 CHECK (cycle_days > 0),
    disbursement_date DATE NOT NULL,
    actual_amount DECIMAL(15,2) NOT NULL CHECK (actual_amount > 0),
    principal_rate_per_period DECIMAL(5,2) NOT NULL CHECK (principal_rate_per_period >= 0),
    number_of_periods INTEGER NOT NULL CHECK (number_of_periods > 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'defaulted', 'cancelled')),
    notes TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
SELECT '✅ loans 表重建完成' as step_3;

-- ============================================
-- 第四步：修复 repayments 表
-- ============================================
ALTER TABLE repayments RENAME COLUMN repayment_date TO payment_date;
ALTER TABLE repayments ADD COLUMN IF NOT EXISTS due_date DATE;
ALTER TABLE repayments ADD COLUMN IF NOT EXISTS excess_amount DECIMAL(15,2) DEFAULT 0;
ALTER TABLE repayments ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);
SELECT '✅ repayments 表修复完成' as step_4;

-- ============================================
-- 第五步：创建触发器和索引
-- ============================================
-- 触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 添加触发器
DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_loans_updated_at ON loans;
CREATE TRIGGER update_loans_updated_at
    BEFORE UPDATE ON loans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 性能索引
CREATE INDEX IF NOT EXISTS idx_customers_customer_code ON customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_approval_status ON customers(approval_status);
CREATE INDEX IF NOT EXISTS idx_loans_customer_id ON loans(customer_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status);
CREATE INDEX IF NOT EXISTS idx_repayments_loan_id ON repayments(loan_id);
CREATE INDEX IF NOT EXISTS idx_repayments_payment_date ON repayments(payment_date);
SELECT '✅ 触发器和索引创建完成' as step_5;

-- ============================================
-- 第六步：更新 RLS 策略
-- ============================================
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE repayments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON customers;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON loans;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON repayments;

CREATE POLICY "Enable all operations for authenticated users" ON customers
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON loans
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON repayments
    FOR ALL USING (auth.role() = 'authenticated');
SELECT '✅ RLS 策略更新完成' as step_6;

-- ============================================
-- 第七步：验证结果
-- ============================================
SELECT 'customers' as table_name, count(*) as record_count FROM customers
UNION ALL
SELECT 'loans' as table_name, count(*) as record_count FROM loans
UNION ALL
SELECT 'repayments' as table_name, count(*) as record_count FROM repayments;

-- 最终状态检查
SELECT '🎉 前后端统一完成！数据库结构已优化' as final_status;

-- ============================================
-- 执行完成后的提醒
-- ============================================
/*
✅ 迁移完成！请执行以下验证步骤：

1. 刷新前端应用页面
2. 测试客户管理功能
3. 测试还款记录功能
4. 检查浏览器控制台是否有错误

如果遇到问题，可以从备份表恢复：
- customers_backup
- loans_backup  
- repayments_backup
*/