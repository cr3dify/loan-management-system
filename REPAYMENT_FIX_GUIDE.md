# 还款功能修复指南

## 问题分析

根据错误日志 `Failed to load resource: the server responded with a status of 400` 和 `保存还款记录失败`，还款功能无法正常工作的主要原因：

### 1. 环境变量未配置 ❌
- Supabase 连接配置缺失
- 无法连接到后端数据库

### 2. 数据库字段名不一致 ❌
- 前端代码: `payment_date`
- 数据库表: `repayment_date` (根据某些脚本)
- 需要统一字段命名

### 3. 数据库表结构可能缺失 ❌
- repayments 表可能不存在或结构不完整

## 修复步骤

### 步骤 1: 配置 Supabase 环境变量

1. 创建 `.env.local` 文件：
```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```

2. 从 Supabase Dashboard 获取这些值：
   - 项目URL: Project Settings → API → Project URL
   - 匿名密钥: Project Settings → API → Project API keys → anon/public

### 步骤 2: 执行数据库修复脚本

在 Supabase SQL Editor 中运行 `scripts/fix_repayment_fields.sql`：

```sql
-- 这个脚本会：
-- 1. 统一字段名为 payment_date
-- 2. 确保表结构完整
-- 3. 更新 RLS 策略
-- 4. 创建必需的索引
```

### 步骤 3: 重启开发服务器

```bash
# 停止当前服务器 (Ctrl+C)
# 重新启动
npm run dev
```

### 步骤 4: 验证修复

1. 访问 http://localhost:3001/repayments
2. 尝试添加还款记录
3. 检查浏览器开发者工具的 Network 标签，确认没有 400 错误

## 已修复的代码问题

✅ **字段名统一**: RepaymentForm 中统一使用 `payment_date`
✅ **类型定义更新**: types.ts 中字段名保持一致  
✅ **显示重复修复**: RepaymentList 中修复了重复显示本金的问题

## 下一步

请按照上述步骤操作：
1. 首先配置 Supabase 环境变量
2. 在 Supabase 中执行数据库修复脚本
3. 重启开发服务器并测试

如果仍有问题，请提供：
- Supabase 控制台中的错误日志
- 浏览器开发者工具中的 Network 错误详情