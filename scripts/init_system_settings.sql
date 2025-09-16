-- =========================================================================
-- 初始化系统设置数据
-- 在 Supabase SQL Editor 中执行此脚本
-- =========================================================================

-- 1. 确保 system_settings 表存在
CREATE TABLE IF NOT EXISTS public.system_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT NOT NULL,
    setting_type VARCHAR(20) DEFAULT 'string' CHECK (setting_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    is_editable BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 插入默认系统设置
INSERT INTO public.system_settings (setting_key, setting_value, setting_type, description, is_editable) VALUES
-- 基础设置
('company_name', '贷款管理系统', 'string', '公司名称', true),
('currency_symbol', 'RM', 'string', '货币符号', true),
('default_penalty_rate', '5.0', 'number', '默认罚金率 (%)', true),
('system_version', '1.0.0', 'string', '系统版本', false),

-- 贷款设置
('max_loan_amount', '100000', 'number', '最大贷款金额', true),
('min_loan_amount', '1000', 'number', '最小贷款金额', true),
('default_periods', '12', 'number', '默认还款期数', true),
('default_principal_rate', '10.0', 'number', '默认本金还款率 (%)', true),
('default_interest_rate', '15.0', 'number', '默认利率 (%)', true),

-- 业务设置
('auto_calculate_penalty', 'true', 'boolean', '自动计算罚金', true),
('allow_partial_payment', 'true', 'boolean', '允许部分还款', true),
('require_approval', 'false', 'boolean', '需要审批', true),
('send_notifications', 'true', 'boolean', '发送通知', true),

-- 系统设置
('backup_frequency', 'daily', 'string', '备份频率', true),
('session_timeout', '30', 'number', '会话超时时间 (分钟)', true),
('max_login_attempts', '5', 'number', '最大登录尝试次数', true),

-- 报表设置
('report_retention_days', '365', 'number', '报表保留天数', true),
('auto_generate_reports', 'false', 'boolean', '自动生成报表', true),
('report_format', 'pdf', 'string', '默认报表格式', true)

ON CONFLICT (setting_key) DO UPDATE SET
    setting_value = EXCLUDED.setting_value,
    setting_type = EXCLUDED.setting_type,
    description = EXCLUDED.description,
    is_editable = EXCLUDED.is_editable,
    updated_at = NOW();

-- 3. 创建更新时间戳触发器
CREATE OR REPLACE FUNCTION public.update_system_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_system_settings_updated_at ON public.system_settings;
CREATE TRIGGER trigger_update_system_settings_updated_at
    BEFORE UPDATE ON public.system_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_system_settings_updated_at();

-- 4. 设置行级安全策略
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- 只有管理员可以查看和修改系统设置
CREATE POLICY "Only admins can manage system settings" ON public.system_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM auth.users 
            WHERE auth.users.id = auth.uid 
            AND (
                auth.users.app_metadata->>'role' IN ('admin', 'super_admin')
                OR auth.users.user_metadata->>'role' IN ('admin', 'super_admin')
            )
        )
    );

-- 5. 验证数据
SELECT 
    setting_key,
    setting_value,
    setting_type,
    description,
    is_editable
FROM public.system_settings 
ORDER BY setting_key;

SELECT '🎉 系统设置初始化完成！' as status;
