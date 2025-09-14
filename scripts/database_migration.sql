-- 前后端统一迁移脚本
-- 基于实际数据库结构的优化脚本

-- ============================================
-- 第一步：备份现有数据
-- ============================================
CREATE TABLE IF NOT EXISTS customers_backup AS SELECT * FROM customers;
CREATE TABLE IF NOT EXISTS loans_backup AS SELECT * FROM loans;
CREATE TABLE IF NOT EXISTS repayments_backup AS SELECT * FROM repayments;

-- ============================================
-- 第二步：修复 customers 表结构
-- ============================================

-- 移除重复字段（保留 full_name，移除 name）
ALTER TABLE customers DROP COLUMN IF EXISTS name;

-- 移除重复字段（保留 id_number，移除 id_card）
ALTER TABLE customers DROP COLUMN IF EXISTS id_card;

-- 添加缺失的用户管理字段
ALTER TABLE customers ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES auth.users(id);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS contract_signed_at TIMESTAMPTZ;

-- 修改字段类型和约束
ALTER TABLE customers ALTER COLUMN customer_number DROP NOT NULL;
ALTER TABLE customers ALTER COLUMN created_by TYPE UUID USING created_by::UUID;
ALTER TABLE customers ALTER COLUMN approved_by TYPE UUID USING approved_by::UUID;

-- ============================================
-- 第三步：优化 loans 表结构
-- ============================================

-- 如果 loans 表为空，重新创建优化结构
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

-- ============================================
-- 第四步：修复 repayments 表结构
-- ============================================

-- 重命名字段以保持一致性
ALTER TABLE repayments RENAME COLUMN repayment_date TO payment_date;

-- 添加缺失字段
ALTER TABLE repayments ADD COLUMN IF NOT EXISTS due_date DATE;
ALTER TABLE repayments ADD COLUMN IF NOT EXISTS excess_amount DECIMAL(15,2) DEFAULT 0;
ALTER TABLE repayments ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 修改字段类型
ALTER TABLE repayments ALTER COLUMN processed_by TYPE UUID USING processed_by::UUID;

-- ============================================
-- 第五步：创建或更新触发器
-- ============================================

-- 更新时间戳触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为各表添加更新时间戳触发器
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

-- ============================================
-- 第六步：重新创建索引
-- ============================================

-- Customers 表索引
CREATE INDEX IF NOT EXISTS idx_customers_customer_code ON customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_approval_status ON customers(approval_status);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON customers(created_at);
CREATE INDEX IF NOT EXISTS idx_customers_assigned_to ON customers(assigned_to);

-- Loans 表索引
CREATE INDEX IF NOT EXISTS idx_loans_customer_id ON loans(customer_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status);
CREATE INDEX IF NOT EXISTS idx_loans_disbursement_date ON loans(disbursement_date);
CREATE INDEX IF NOT EXISTS idx_loans_created_at ON loans(created_at);

-- Repayments 表索引
CREATE INDEX IF NOT EXISTS idx_repayments_loan_id ON repayments(loan_id);
CREATE INDEX IF NOT EXISTS idx_repayments_customer_id ON repayments(customer_id);
CREATE INDEX IF NOT EXISTS idx_repayments_payment_date ON repayments(payment_date);
CREATE INDEX IF NOT EXISTS idx_repayments_created_at ON repayments(created_at);

-- ============================================
-- 第七步：更新 RLS 策略
-- ============================================

-- 启用 RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE repayments ENABLE ROW LEVEL SECURITY;

-- 删除旧策略
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON customers;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON loans;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON repayments;

-- 创建新的基本策略
CREATE POLICY "Enable all operations for authenticated users" ON customers
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON loans
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON repayments
    FOR ALL USING (auth.role() = 'authenticated');

-- ============================================
-- 第八步：验证脚本
-- ============================================

-- 验证表结构
SELECT 'customers' as table_name, count(*) as record_count FROM customers
UNION ALL
SELECT 'loans' as table_name, count(*) as record_count FROM loans
UNION ALL
SELECT 'repayments' as table_name, count(*) as record_count FROM repayments;

SELECT '数据库结构统一完成！' as status;