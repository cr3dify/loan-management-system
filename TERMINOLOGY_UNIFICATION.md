# 贷款管理系统术语统一说明

## 📋 统一概览

本次统一主要针对系统中的两个核心概念进行规范化：
1. **贷款模式命名**：mode1/mode2 → scenario_a/scenario_b/scenario_c
2. **还款类型术语**：payment_type → repayment_type

## 🎯 贷款模式统一

### 原始模式 → 新模式映射

| 原模式 | 新模式 | 说明 | 计算公式 |
|--------|--------|------|----------|
| `mode1` | `scenario_a` | **场景A：利息+押金** | 到手 = 贷款额 - 利息 - 押金 |
| `mode2` | `scenario_b` | **场景B：只收利息** | 到手 = 贷款额 - 利息 |
| 新增 | `scenario_c` | **场景C：只收押金** | 到手 = 贷款额 - 押金 |

### 具体示例（RM 10,000 贷款）

```javascript
// 场景A：利息+押金
// 贷款RM10,000，利息10%，押金RM1,000
// 到手 = 10,000 - 1,000(利息) - 1,000(押金) = RM8,000

// 场景B：只收利息  
// 贷款RM10,000，利息10%，押金RM0
// 到手 = 10,000 - 1,000(利息) = RM9,000

// 场景C：只收押金
// 贷款RM10,000，利息0%，押金RM1,000
// 到手 = 10,000 - 1,000(押金) = RM9,000
```

## 🔄 还款类型统一

### 术语映射表

| 原术语 | 新术语 | 中文说明 |
|--------|--------|----------|
| `regular` | `partial_principal` | 部分还本金+利息 |
| `partial` | `partial_principal` | 部分还本金+利息 |
| `full` | `full_settlement` | 一次性结清 |
| `interest_only` | `interest_only` | 只还利息 ✅ |

## 📁 已更新的文件

### 核心类型定义
- ✅ `lib/types.ts` - 更新接口定义

### 计算引擎
- ✅ `lib/loan-calculator.ts` - 支持三种场景的计算逻辑

### 前端组件
- ✅ `components/customer-form.tsx` - 客户表单贷款模式选择
- ✅ `components/loan-calculator-page.tsx` - 计算器页面
- ✅ `components/repayment-form.tsx` - 还款表单
- ✅ `components/repayment-list.tsx` - 还款列表显示
- ✅ `components/dashboard.tsx` - 仪表板数据展示

### 数据库脚本
- ✅ `scripts/unify_terminology.sql` - 数据库约束和数据迁移脚本

## 🗄️ 数据库迁移

执行 `scripts/unify_terminology.sql` 脚本将：

1. **更新约束**: 支持新的枚举值
2. **数据迁移**: 自动转换现有数据
3. **字段清理**: 移除过时的字段
4. **验证视图**: 创建数据一致性检查

## 🎨 用户界面更新

### 贷款模式选择
```html
<select>
  <option value="scenario_a">场景A：利息+押金</option>
  <option value="scenario_b">场景B：只收利息</option>
  <option value="scenario_c">场景C：只收押金</option>
</select>
```

### 还款类型选择
```html
<select>
  <option value="interest_only">只还利息</option>
  <option value="partial_principal">部分还本金+利息</option>
  <option value="full_settlement">一次性结清</option>
</select>
```

## ⚡ 系统兼容性

### 向后兼容
- 数据库脚本自动处理现有数据迁移
- 老数据会被自动映射到新术语
- 无需手动数据清理

### API 兼容性
- 前端完全使用新术语
- 数据库约束已更新
- 类型定义已统一

## 🎯 核心改进

### 1. 更直观的命名
- ❌ `mode1` / `mode2` (技术术语)
- ✅ `scenario_a` / `scenario_b` / `scenario_c` (业务场景)

### 2. 完整的场景覆盖
- ✅ **场景A**: 利息+押金 → 风控最严格
- ✅ **场景B**: 只收利息 → 平衡风控与现金流
- ✅ **场景C**: 只收押金 → 灵活借贷

### 3. 统一的还款术语
- ✅ 前后端使用相同的 `repayment_type`
- ✅ 数据库约束与代码定义一致
- ✅ 用户界面术语标准化

## 🔍 验证清单

- [x] TypeScript 编译无错误
- [x] 前端组件正常显示新术语
- [x] 计算引擎支持三种场景
- [x] 数据库约束已更新
- [x] 向后兼容性保证
- [x] 用户界面友好

## 🚀 下一步建议

1. **测试部署**: 在测试环境验证数据迁移
2. **用户培训**: 向用户说明新的术语体系
3. **文档更新**: 更新用户手册和操作指南
4. **监控数据**: 确保生产环境迁移顺利

---

**✅ 术语统一完成！系统现在使用更直观、更一致的业务术语。**