-- =========================================================================
-- 简化的 Phase 2 测试数据脚本
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 添加测试用户（只使用允许的角色）
INSERT INTO public.users (id, name, role, email, created_at, updated_at)
VALUES 
    ('00000000-0000-0000-0000-000000000001', '测试员工', 'employee', 'employee@test.com', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000002', '测试秘书', 'secretary', 'secretary@test.com', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000003', '测试管理员', 'admin', 'admin@test.com', NOW(), NOW())
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
     200.00, '购买文具', '2024-01-12', 'approved', NOW())
ON CONFLICT (id) DO NOTHING;

-- 4. 更新已审批费用的审批人信息
UPDATE public.expenses 
SET approved_by = '00000000-0000-0000-0000-000000000002', approved_at = NOW()
WHERE id IN ('10000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000004');

-- 5. 验证数据
SELECT '测试数据添加完成！' as status;
SELECT '费用数据统计:' as info;
SELECT 
    approval_status,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM public.expenses 
GROUP BY approval_status;
