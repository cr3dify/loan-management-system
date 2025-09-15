-- 简化版紧急修复脚本 - 在 Supabase SQL Editor 中执行

-- 添加 remaining_principal 字段（解决 column does not exist 错误）
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS remaining_principal DECIMAL(15,2) DEFAULT 0;

-- 验证字段是否添加成功
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'repayments' AND column_name = 'remaining_principal';

SELECT '✅ remaining_principal 字段修复完成！' as status;