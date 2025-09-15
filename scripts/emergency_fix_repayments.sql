-- =========================================================================
-- 紧急修复：还款记录插入失败问题
-- 错误: column "remaining_principal" does not exist
-- =========================================================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 检查 repayments 表的当前结构
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. 添加缺失的 remaining_principal 字段
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS remaining_principal DECIMAL(15,2) DEFAULT 0;

-- 3. 确保所有必需字段都存在
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(20) DEFAULT 'cash' 
    CHECK (payment_method IN ('cash', 'bank_transfer', 'check', 'other'));

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS receipt_number VARCHAR(100);

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS processed_by UUID REFERENCES auth.users(id);

ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 4. 验证表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT '修复完成！repayments 表结构已更新' as status;