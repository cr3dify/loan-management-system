-- 修复用户权限设置
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 检查当前用户信息（调试用）
DO $$
BEGIN
    RAISE NOTICE '=== 当前用户信息 ===';
    FOR rec IN 
        SELECT 
            id,
            email,
            raw_user_meta_data,
            raw_app_meta_data,
            is_super_admin,
            created_at
        FROM auth.users 
        WHERE email = 'tonyyam151@gmail.com'
    LOOP
        RAISE NOTICE 'ID: %', rec.id;
        RAISE NOTICE 'Email: %', rec.email;
        RAISE NOTICE 'User Meta: %', rec.raw_user_meta_data;
        RAISE NOTICE 'App Meta: %', rec.raw_app_meta_data;
        RAISE NOTICE 'Is Super Admin: %', rec.is_super_admin;
    END LOOP;
END $$;

-- 2. 强制设置管理员权限（多重保障）
UPDATE auth.users 
SET 
  -- 设置用户元数据中的角色
  raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || 
                       '{"role": "admin", "username": "admin", "full_name": "Administrator"}'::jsonb,
  
  -- 设置应用元数据中的角色
  raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) || 
                      '{"role": "admin", "provider": "email", "providers": ["email"]}'::jsonb,
  
  -- 设置超级管理员标志
  is_super_admin = true,
  
  -- 确保邮箱已确认
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  confirmed_at = COALESCE(confirmed_at, NOW()),
  
  updated_at = NOW()
WHERE email = 'tonyyam151@gmail.com';

-- 3. 验证更新结果
SELECT 
  '=== 更新后的用户信息 ===' as info,
  id,
  email,
  raw_user_meta_data->>'role' as user_role,
  raw_app_meta_data->>'role' as app_role,
  is_super_admin,
  email_confirmed_at IS NOT NULL as email_confirmed,
  confirmed_at IS NOT NULL as account_confirmed,
  updated_at
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';

-- 4. 检查JSON结构是否正确
SELECT 
  '=== JSON结构检查 ===' as info,
  jsonb_pretty(raw_user_meta_data) as user_meta_formatted,
  jsonb_pretty(raw_app_meta_data) as app_meta_formatted
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';

-- 5. 测试角色提取
SELECT 
  '=== 角色提取测试 ===' as info,
  raw_user_meta_data->>'role' as extracted_user_role,
  raw_app_meta_data->>'role' as extracted_app_role,
  CASE 
    WHEN raw_app_meta_data->>'role' IS NOT NULL THEN raw_app_meta_data->>'role'
    WHEN raw_user_meta_data->>'role' IS NOT NULL THEN raw_user_meta_data->>'role'
    ELSE 'employee'
  END as final_role
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';