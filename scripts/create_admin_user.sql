-- 更新现有用户的管理员元数据
-- 请在 Supabase SQL 编辑器中执行此脚本

-- 1. 更新用户的元数据，添加管理员信息
UPDATE auth.users 
SET 
  raw_user_meta_data = '{"username": "admin", "full_name": "Administrator", "role": "admin"}',
  email_confirmed_at = NOW(),
  updated_at = NOW()
WHERE email = 'tonyyam151@gmail.com';

-- 2. 验证更新结果
SELECT 
  id,
  email,
  email_confirmed_at,
  confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';

-- 3. 如果需要，也可以更新 raw_app_meta_data
UPDATE auth.users 
SET 
  raw_app_meta_data = '{"provider": "email", "providers": ["email"], "role": "admin"}',
  updated_at = NOW()
WHERE email = 'tonyyam151@gmail.com';

-- 4. 最终验证
SELECT 
  id,
  email,
  email_confirmed_at,
  confirmed_at,
  raw_user_meta_data,
  raw_app_meta_data,
  created_at,
  updated_at
FROM auth.users 
WHERE email = 'tonyyam151@gmail.com';
