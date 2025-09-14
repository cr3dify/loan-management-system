# 数据库脚本管理说明

## 📁 当前文件结构

### 🎯 **主要脚本（建议使用）**
- `complete_main_database.sql` - **✅ 推荐使用的完整主脚本**
  - 包含所有功能：表结构 + 术语统一 + 前后端对齐
  - 适用于新部署和现有数据库升级
  - 一键部署，无需其他脚本

### 📦 **归档脚本（archive/ 目录）**
已废弃但保留备查的脚本，包括：
- `complete_database_setup.sql` - 原始主脚本（功能不完整）
- `unify_terminology.sql` - 术语统一脚本（已整合到主脚本）
- `final_database_unification.sql` - 中间版本脚本
- `fix_main_database_schema.sql` - 修复脚本
- 其他历史版本和实验性脚本

### 🔧 **工具脚本（保留）**
- `create_admin_user.sql` - 创建管理员用户
- `check_rls_policies.sql` - 检查安全策略
- `check_user_permissions.sql` - 检查用户权限
- `fix_rls_policies.sql` - 修复安全策略
- `set_super_admin.sql` - 设置超级管理员

## 🚀 **使用建议**

### **新环境部署**
```sql
-- 只需要运行这一个脚本
\i complete_main_database.sql
```

### **现有环境升级**
```sql
-- 同样只需要运行这一个脚本
-- 会自动检测并兼容现有数据
\i complete_main_database.sql
```

### **问题排查**
如果遇到问题，可以参考 archive/ 目录下的历史脚本了解升级路径。

## 📋 **归档原因**

| 脚本文件 | 归档原因 | 替代方案 |
|---------|----------|----------|
| `complete_database_setup.sql` | 功能不完整，缺少前端期望字段 | `complete_main_database.sql` |
| `unify_terminology.sql` | 已整合到主脚本 | `complete_main_database.sql` |
| `final_database_unification.sql` | 中间版本，已被优化 | `complete_main_database.sql` |
| `fix_main_database_schema.sql` | 专用修复脚本，已整合 | `complete_main_database.sql` |

## ⚠️ **注意事项**

1. **不要删除旧脚本** - 保留完整的升级路径记录
2. **统一使用主脚本** - 避免混用不同版本的脚本
3. **备份数据** - 运行任何脚本前请备份数据库
4. **测试验证** - 在测试环境先验证脚本功能

## 🎯 **最佳实践**

- ✅ 使用 `complete_main_database.sql` 进行所有部署
- ✅ 定期备份数据库
- ✅ 在测试环境验证脚本
- ❌ 不要混用多个脚本
- ❌ 不要删除历史脚本