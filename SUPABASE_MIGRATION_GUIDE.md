# Supabase 数据库迁移执行指南

## 🎯 目标
统一前端 TypeScript 类型定义与 Supabase 数据库结构，确保完全一致性。

## 📋 当前状态检查

### ✅ 已发现的不一致问题
1. **customers 表**：存在重复字段 `name` 和 `full_name`，`id_card` 和 `id_number`
2. **repayments 表**：字段名 `repayment_date` 需要改为 `payment_date`
3. **loans 表**：结构需要优化，添加核心业务字段

## 🚀 执行步骤

### 第一步：在 Supabase SQL Editor 中执行备份

```sql
-- 1. 备份现有数据（必须先执行）
CREATE TABLE customers_backup AS SELECT * FROM customers;
CREATE TABLE loans_backup AS SELECT * FROM loans;
CREATE TABLE repayments_backup AS SELECT * FROM repayments;

SELECT '备份完成' as status;
```

### 第二步：修复 customers 表结构

```sql
-- 2.1 数据迁移（保留数据）
UPDATE customers SET full_name = name WHERE full_name IS NULL OR full_name = '';
UPDATE customers SET id_number = id_card WHERE id_number IS NULL OR id_number = '';

-- 2.2 移除重复字段
ALTER TABLE customers DROP COLUMN IF EXISTS name;
ALTER TABLE customers DROP COLUMN IF EXISTS id_card;

-- 2.3 添加缺失字段
ALTER TABLE customers ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES auth.users(id);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS approved_at TIMESTAMPTZ;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS contract_signed_at TIMESTAMPTZ;

-- 2.4 修改字段约束
ALTER TABLE customers ALTER COLUMN customer_number DROP NOT NULL;

SELECT '客户表结构修复完成' as status;
```

### 第三步：优化 loans 表结构

```sql
-- 3.1 检查 loans 表是否有数据
SELECT count(*) as loan_count FROM loans;

-- 3.2 如果 loans 表为空，重新创建（推荐）
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

SELECT '贷款表结构优化完成' as status;
```

### 第四步：修复 repayments 表结构

```sql
-- 4.1 重命名字段
ALTER TABLE repayments RENAME COLUMN repayment_date TO payment_date;

-- 4.2 添加缺失字段
ALTER TABLE repayments ADD COLUMN IF NOT EXISTS due_date DATE;
ALTER TABLE repayments ADD COLUMN IF NOT EXISTS excess_amount DECIMAL(15,2) DEFAULT 0;
ALTER TABLE repayments ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

SELECT '还款表结构修复完成' as status;
```

### 第五步：创建触发器和索引

```sql
-- 5.1 创建更新时间戳触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5.2 添加触发器
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

-- 5.3 创建性能索引
CREATE INDEX IF NOT EXISTS idx_customers_customer_code ON customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_status ON customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_approval_status ON customers(approval_status);
CREATE INDEX IF NOT EXISTS idx_loans_customer_id ON loans(customer_id);
CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status);
CREATE INDEX IF NOT EXISTS idx_repayments_loan_id ON repayments(loan_id);
CREATE INDEX IF NOT EXISTS idx_repayments_payment_date ON repayments(payment_date);

SELECT '触发器和索引创建完成' as status;
```

### 第六步：更新 RLS 策略

```sql
-- 6.1 启用 RLS
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE repayments ENABLE ROW LEVEL SECURITY;

-- 6.2 删除旧策略并创建新策略
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON customers;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON loans;
DROP POLICY IF EXISTS "Enable all operations for authenticated users" ON repayments;

CREATE POLICY "Enable all operations for authenticated users" ON customers
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON loans
    FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Enable all operations for authenticated users" ON repayments
    FOR ALL USING (auth.role() = 'authenticated');

SELECT 'RLS 策略更新完成' as status;
```

### 第七步：验证迁移结果

```sql
-- 7.1 验证表结构
SELECT 'customers' as table_name, count(*) as record_count FROM customers
UNION ALL
SELECT 'loans' as table_name, count(*) as record_count FROM loans
UNION ALL
SELECT 'repayments' as table_name, count(*) as record_count FROM repayments;

-- 7.2 检查字段是否正确
SELECT * FROM customers LIMIT 1;
SELECT * FROM loans LIMIT 1;
SELECT * FROM repayments LIMIT 1;

SELECT '✅ 数据库结构统一完成！' as final_status;
```

## ⚠️ 重要提醒

1. **按顺序执行**：必须按照步骤顺序执行，不要跳过
2. **备份优先**：第一步备份是必须的，确保数据安全
3. **检查结果**：每步执行后检查返回的状态信息
4. **测试功能**：迁移完成后测试前端应用的所有功能

## 🔄 回滚方案

如果迁移出现问题，可以从备份表恢复：

```sql
-- 紧急回滚（如果需要）
DROP TABLE customers;
DROP TABLE loans;
DROP TABLE repayments;

ALTER TABLE customers_backup RENAME TO customers;
ALTER TABLE loans_backup RENAME TO loans;
ALTER TABLE repayments_backup RENAME TO repayments;
```

## 📞 执行后验证

迁移完成后，请：
1. 刷新前端应用页面
2. 测试客户创建、编辑功能
3. 测试还款记录功能
4. 检查是否有控制台错误

**准备好后，请在 Supabase SQL Editor 中逐步执行上述 SQL 语句！**