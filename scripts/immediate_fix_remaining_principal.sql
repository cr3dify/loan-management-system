-- =========================================================================
-- 立即修复：添加 remaining_principal 字段
-- 这是最简单直接的修复方案，请在 Supabase SQL Editor 中执行
-- =========================================================================

-- 简单粗暴地添加字段（如果不存在）
ALTER TABLE public.repayments 
ADD COLUMN IF NOT EXISTS remaining_principal DECIMAL(15,2) DEFAULT 0;

-- 验证字段是否添加成功
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'repayments' 
    AND table_schema = 'public'
    AND column_name = 'remaining_principal';

-- 显示确认信息
SELECT '✅ remaining_principal 字段修复完成！现在可以正常使用还款功能了。' as status;