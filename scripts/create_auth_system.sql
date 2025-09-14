-- 创建身份验证系统和默认用户

-- 更新用户表，添加用户名字段
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS username VARCHAR(50) UNIQUE;

-- 修复字段名，使用 name 而不是 full_name
-- 插入默认管理员用户到 public.users 表
INSERT INTO public.users (id, email, username, name, role, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  'admin@system.local',
  'admin',
  '系统管理员',
  'admin',
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM public.users WHERE username = 'admin'
);

-- 创建登录会话表
CREATE TABLE IF NOT EXISTS public.user_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  session_token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 启用 RLS
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

-- 创建 RLS 策略
CREATE POLICY "Users can view own sessions" ON public.user_sessions
  FOR SELECT USING (user_id IN (SELECT id FROM public.users WHERE id = auth.uid()));

CREATE POLICY "Users can insert own sessions" ON public.user_sessions
  FOR INSERT WITH CHECK (user_id IN (SELECT id FROM public.users WHERE id = auth.uid()));

CREATE POLICY "Users can update own sessions" ON public.user_sessions
  FOR UPDATE USING (user_id IN (SELECT id FROM public.users WHERE id = auth.uid()));

CREATE POLICY "Users can delete own sessions" ON public.user_sessions
  FOR DELETE USING (user_id IN (SELECT id FROM public.users WHERE id = auth.uid()));

-- 修复函数中的字段名，使用 name 而不是 full_name
-- 添加登录验证函数
CREATE OR REPLACE FUNCTION public.authenticate_user(
  p_username TEXT,
  p_password TEXT
) RETURNS TABLE(
  user_id UUID,
  username TEXT,
  user_name TEXT,
  role TEXT,
  success BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.username,
    u.name,
    u.role,
    (u.password_hash = crypt(p_password, u.password_hash)) as success
  FROM public.users u
  WHERE u.username = p_username;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
