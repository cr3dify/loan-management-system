-- =========================================================================
-- Phase 2 功能测试脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 测试费用类型表
SELECT '🔍 测试费用类型表...' as status;
SELECT COUNT(*) as expense_type_count FROM public.expense_types;
SELECT * FROM public.expense_types LIMIT 5;

-- 2. 测试费用表
SELECT '🔍 测试费用表...' as status;
SELECT COUNT(*) as expense_count FROM public.expenses;

-- 3. 测试员工盈亏表
SELECT '🔍 测试员工盈亏表...' as status;
SELECT COUNT(*) as profit_count FROM public.employee_profits;

-- 4. 测试审批记录表
SELECT '🔍 测试审批记录表...' as status;
SELECT COUNT(*) as approval_count FROM public.approval_records;

-- 5. 测试权限策略
SELECT '🔍 测试权限策略...' as status;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename IN ('expenses', 'employee_profits', 'approval_records', 'expense_types')
ORDER BY tablename, policyname;

-- 6. 测试RPC函数
SELECT '🔍 测试RPC函数...' as status;
SELECT 
    proname as function_name,
    proargnames as argument_names,
    prorettype::regtype as return_type
FROM pg_proc 
WHERE proname = 'calculate_employee_profit';

-- 7. 创建测试数据
SELECT '🔍 创建测试数据...' as status;

-- 创建测试用户（如果不存在）
INSERT INTO public.users (id, email, full_name, role, is_active)
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'test@example.com', '测试用户', 'employee', true),
    ('00000000-0000-0000-0000-000000000002', 'admin@example.com', '管理员', 'admin', true)
ON CONFLICT (id) DO NOTHING;

-- 创建测试费用
INSERT INTO public.expenses (
    employee_id,
    expense_type_id,
    amount,
    description,
    expense_date,
    approval_status
)
SELECT 
    '00000000-0000-0000-0000-000000000001',
    et.id,
    100.00,
    '测试交通费',
    CURRENT_DATE,
    'pending'
FROM public.expense_types et
WHERE et.name = '交通费'
LIMIT 1;

-- 8. 测试员工盈亏计算
SELECT '🔍 测试员工盈亏计算...' as status;
SELECT public.calculate_employee_profit(
    '00000000-0000-0000-0000-000000000001',
    EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER,
    EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER
) as profit_calculation;

-- 9. 验证数据完整性
SELECT '🔍 验证数据完整性...' as status;

-- 检查外键约束
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name IN ('expenses', 'employee_profits', 'approval_records')
ORDER BY tc.table_name;

-- 10. 性能测试
SELECT '🔍 性能测试...' as status;

-- 测试索引
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename IN ('expenses', 'employee_profits', 'approval_records', 'expense_types')
ORDER BY tablename, indexname;

-- 11. 清理测试数据
SELECT '🧹 清理测试数据...' as status;
DELETE FROM public.expenses WHERE employee_id = '00000000-0000-0000-0000-000000000001';
DELETE FROM public.employee_profits WHERE employee_id = '00000000-0000-0000-0000-000000000001';
DELETE FROM public.approval_records WHERE approver_id = '00000000-0000-0000-0000-000000000001';

-- 12. 最终验证
SELECT '✅ Phase 2 功能测试完成！' as status;

-- 显示表结构摘要
SELECT 
    'expense_types' as table_name,
    COUNT(*) as record_count,
    '费用类型' as description
FROM public.expense_types
UNION ALL
SELECT 
    'expenses' as table_name,
    COUNT(*) as record_count,
    '费用记录' as description
FROM public.expenses
UNION ALL
SELECT 
    'employee_profits' as table_name,
    COUNT(*) as record_count,
    '员工盈亏' as description
FROM public.employee_profits
UNION ALL
SELECT 
    'approval_records' as table_name,
    COUNT(*) as record_count,
    '审批记录' as description
FROM public.approval_records
ORDER BY table_name;
