-- 将用户设置为超级管理员
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 将用户设置为超级管理员
UPDATE auth.users 
SET 
  is_super_admin = true,
  raw_app_meta_data = '{"role": "super_admin", "provider": "email", "providers": ["email"]}',
  raw_user_meta_data = '{"role": "super_admin", "username": "admin", "full_name": "Administrator"}',
  updated_at = NOW()
WHERE email = 'tonyyam151@gmail.com';

-- 2. 验证超级管理员设置
SELECT 
  id,
  email,
  is_super_admin,
  raw_user_meta_data,
  raw_app_meta_data,
  email_confirmed_at,
  confirmed_at,
  updated_at
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';

-- 3. 如果需要，也可以检查用户权限
SELECT 
  email,
  role,
  is_super_admin,
  raw_user_meta_data->>'role' as user_role,
  raw_app_meta_data->>'role' as app_role
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';
