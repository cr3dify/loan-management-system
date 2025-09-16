-- =========================================================================
-- Phase 2 测试数据添加脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 确保有测试用户（如果不存在）
INSERT INTO public.users (id, name, role, email, created_at, updated_at)
VALUES 
    ('00000000-0000-0000-0000-000000000001', '测试员工', 'employee', 'employee@test.com', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000002', '测试秘书', 'secretary', 'secretary@test.com', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000003', '测试经理', 'manager', 'manager@test.com', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000004', '测试管理员', 'admin', 'admin@test.com', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 2. 确保费用类型存在
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

-- 3. 添加测试费用数据
INSERT INTO public.expenses (id, employee_id, expense_type_id, amount, description, expense_date, approval_status, created_at)
VALUES 
    -- 待审批的费用
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 
     (SELECT id FROM public.expense_types WHERE name = '交通费' LIMIT 1),
     150.00, '出差打车费', '2024-01-15', 'pending', NOW()),
    
    ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001',
     (SELECT id FROM public.expense_types WHERE name = '文书费' LIMIT 1),
     80.00, '打印合同费用', '2024-01-16', 'pending', NOW()),
    
    -- 已审批的费用
    ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001',
     (SELECT id FROM public.expense_types WHERE name = '客户招待' LIMIT 1),
     300.00, '客户午餐费用', '2024-01-10', 'approved', NOW()),
    
    ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000002',
     (SELECT id FROM public.expense_types WHERE name = '办公用品' LIMIT 1),
     200.00, '购买文具', '2024-01-12', 'approved', NOW()),
    
    -- 被拒绝的费用
    ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001',
     (SELECT id FROM public.expense_types WHERE name = '其他' LIMIT 1),
     500.00, '个人消费', '2024-01-08', 'rejected', NOW())
ON CONFLICT (id) DO NOTHING;

-- 4. 添加审批记录
INSERT INTO public.approval_records (id, record_type, record_id, approver_id, approval_status, approval_level, comments, approved_at, created_at)
VALUES 
    ('20000000-0000-0000-0000-000000000001', 'expense', '10000000-0000-0000-0000-000000000003',
     '00000000-0000-0000-0000-000000000002', 'approved', 1, '费用合理，同意报销', NOW(), NOW()),
    
    ('20000000-0000-0000-0000-000000000002', 'expense', '10000000-0000-0000-0000-000000000004',
     '00000000-0000-0000-0000-000000000002', 'approved', 1, '办公用品采购合理', NOW(), NOW()),
    
    ('20000000-0000-0000-0000-000000000003', 'expense', '10000000-0000-0000-0000-000000000005',
     '00000000-0000-0000-0000-000000000002', 'rejected', 1, '个人消费不能报销', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 5. 添加员工盈亏数据
INSERT INTO public.employee_profits (id, employee_id, period_year, period_month, total_loans, total_repayments, total_expenses, net_profit, roi_percentage, created_at)
VALUES 
    ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 2024, 1, 50000.00, 45000.00, 300.00, -5300.00, -10.60, NOW()),
    ('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 2024, 1, 30000.00, 32000.00, 200.00, 1800.00, 6.00, NOW())
ON CONFLICT (id) DO NOTHING;

-- 6. 更新已审批费用的审批人信息
UPDATE public.expenses 
SET approved_by = '00000000-0000-0000-0000-000000000002', approved_at = NOW()
WHERE id IN ('10000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000004');

UPDATE public.expenses 
SET approved_by = '00000000-0000-0000-0000-000000000002', approved_at = NOW(), rejection_reason = '个人消费不能报销'
WHERE id = '10000000-0000-0000-0000-000000000005';

-- 7. 验证数据
SELECT '测试数据添加完成！' as status;
SELECT '费用数据统计:' as info;
SELECT 
    approval_status,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM public.expenses 
GROUP BY approval_status;

SELECT '费用类型统计:' as info;
SELECT name, COUNT(*) as count FROM public.expense_types GROUP BY name;

SELECT '用户统计:' as info;
SELECT role, COUNT(*) as count FROM public.users WHERE id LIKE '00000000-%' GROUP BY role;
