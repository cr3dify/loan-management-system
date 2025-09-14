# 🔧 Supabase 连接配置指南

## 📋 问题诊断

项目目前**缺少 Supabase 环境变量配置**，这会导致以下问题：
- 🚫 无法连接到 Supabase 数据库
- 🚫 登录功能无法正常工作
- 🚫 所有数据相关功能失效

## 🚀 解决方案

### 1. 创建环境变量文件

在项目根目录创建 `.env.local` 文件：

```bash
# 复制示例文件
cp .env.example .env.local
```

### 2. 获取 Supabase 项目信息

登录 [Supabase Dashboard](https://app.supabase.com)：

1. **选择或创建项目**
2. **进入 Settings → API**
3. **复制以下信息**：
   - Project URL
   - anon (public) key

### 3. 配置环境变量

在 `.env.local` 文件中填入实际值：

```env
# Supabase 项目 URL
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co

# Supabase 匿名密钥
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_actual_anon_key_here
```

### 4. 重启开发服务器

配置完成后重启：

```bash
# 停止当前服务器 (Ctrl+C)
# 重新启动
npm run dev
```

## 🗄️ 数据库设置

配置环境变量后，需要设置数据库：

### 🚀 快速初始化 (推荐)

1. **登录 Supabase Dashboard**
   - 访问 [app.supabase.com](https://app.supabase.com)
   - 进入你的项目

2. **执行快速初始化脚本**
   - 打开 **SQL Editor**
   - 复制 `scripts/quick_database_init.sql` 的内容
   - 粘贴并执行

3. **验证数据库创建**
   ```sql
   -- 检查表是否创建成功
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   ORDER BY table_name;
   ```

### 📋 脚本包含的内容

- ✅ **核心表结构**: customers, loans, repayments, system_settings
- ✅ **示例数据**: 5个客户 + 对应贷款和还款记录
- ✅ **行级安全策略**: 基本的RLS配置
- ✅ **索引优化**: 查询性能优化

### 🔧 完整版本 (可选)

如果需要完整功能，可以执行：
```sql
-- 在 Supabase SQL Editor 中执行
\i scripts/complete_main_database.sql
```

## ✅ 验证连接

成功配置后，你应该能够：
- ✅ 访问登录页面
- ✅ 进行用户认证
- ✅ 查看和管理客户数据

## 🔒 安全注意事项

- ✅ `.env.local` 已在 `.gitignore` 中，不会被提交
- ✅ 只使用 `anon key`，不要在前端使用 `service role key`
- ✅ 生产环境请在部署平台设置环境变量

## 📞 如果遇到问题

1. **检查 Supabase 项目状态** - 确保项目处于活跃状态
2. **验证 URL 格式** - 确保 URL 以 `https://` 开头，以 `.supabase.co` 结尾
3. **检查密钥有效性** - 在 Supabase Dashboard 中重新复制密钥
4. **查看浏览器控制台** - 检查是否有连接错误信息