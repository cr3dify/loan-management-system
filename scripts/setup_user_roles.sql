-- 更新用户角色以测试权限功能
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 查看当前用户的角色信息
SELECT 
  id,
  email,
  raw_user_meta_data,
  raw_app_meta_data,
  created_at
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';

-- 2. 将当前用户设置为管理员角色（确保有所有权限）
UPDATE auth.users 
SET 
  raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'), 
    '{role}', 
    '"admin"'
  ),
  raw_app_meta_data = jsonb_set(
    COALESCE(raw_app_meta_data, '{}'), 
    '{role}', 
    '"admin"'
  ),
  updated_at = NOW()
WHERE email = 'tonyyam151@gmail.com';

-- 3. 验证更新结果
SELECT 
  id,
  email,
  raw_user_meta_data->>'role' as user_role,
  raw_app_meta_data->>'role' as app_role,
  updated_at
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';

-- 4. 如果需要测试员工权限，可以运行以下语句：
-- UPDATE auth.users 
-- SET 
--   raw_user_meta_data = jsonb_set(
--     COALESCE(raw_user_meta_data, '{}'), 
--     '{role}', 
--     '"employee"'
--   ),
--   raw_app_meta_data = jsonb_set(
--     COALESCE(raw_app_meta_data, '{}'), 
--     '{role}', 
--     '"employee"'
--   ),
--   updated_at = NOW()
-- WHERE email = 'tonyyam151@gmail.com';

-- 5. 如果需要测试秘书权限，可以运行以下语句：
-- UPDATE auth.users 
-- SET 
--   raw_user_meta_data = jsonb_set(
--     COALESCE(raw_user_meta_data, '{}'), 
--     '{role}', 
--     '"secretary"'
--   ),
--   raw_app_meta_data = jsonb_set(
--     COALESCE(raw_app_meta_data, '{}'), 
--     '{role}', 
--     '"secretary"'
--   ),
--   updated_at = NOW()
-- WHERE email = 'tonyyam151@gmail.com';