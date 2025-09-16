-- =========================================================================
-- 测试系统设置功能
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 检查系统设置表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'system_settings' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. 检查现有设置
SELECT 
    COUNT(*) as total_settings,
    COUNT(CASE WHEN is_editable = true THEN 1 END) as editable_settings,
    COUNT(CASE WHEN is_editable = false THEN 1 END) as read_only_settings
FROM public.system_settings;

-- 3. 显示所有设置
SELECT 
    setting_key,
    setting_value,
    setting_type,
    description,
    is_editable,
    created_at
FROM public.system_settings 
ORDER BY setting_key;

-- 4. 测试更新设置
DO $$
DECLARE
    test_result record;
BEGIN
    -- 测试更新一个设置
    UPDATE public.system_settings 
    SET setting_value = '测试公司'
    WHERE setting_key = 'company_name'
    RETURNING * INTO test_result;
    
    IF FOUND THEN
        RAISE NOTICE '✅ 设置更新成功: % = %', test_result.setting_key, test_result.setting_value;
    ELSE
        RAISE NOTICE '❌ 设置更新失败';
    END IF;
    
    -- 恢复原值
    UPDATE public.system_settings 
    SET setting_value = '贷款管理系统'
    WHERE setting_key = 'company_name';
    
    RAISE NOTICE '🔄 已恢复原值';
END $$;

-- 5. 检查权限策略
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'system_settings';

-- 6. 检查触发器
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'system_settings';

SELECT '🎉 系统设置测试完成！' as status;
