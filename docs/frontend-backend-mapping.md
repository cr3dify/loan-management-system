# 前端与 Supabase 数据库结构对应关系

## ✅ 修复完成的问题

### 1. ID 类型统一
**问题**: 前端使用 `number`，数据库使用 `UUID`
**修复**: 
- ✅ 前端 types.ts 中所有 ID 字段改为 `string` 类型
- ✅ 相关组件中 ID 比较和操作更新为字符串类型
- ✅ 数据库使用 UUID 主键，确保唯一性

### 2. 字段命名统一
**问题**: 前端期望字段与数据库字段不一致
**修复**:
```typescript
// 前端期望 → 数据库支持
full_name    → name + full_name (两个都支持)
id_number    → id_card + id_number (两个都支持)
```

### 3. 还款记录字段完整性
**问题**: 前端类型定义缺少数据库存在的字段
**修复**:
- ✅ 添加 `excess_amount` 字段 (多余金额)
- ✅ 添加 `due_date` 字段 (应还日期)
- ✅ 添加 `created_by` 字段 (创建人)

### 4. 数据库约束冲突修复
**问题**: CHECK 约束阻止数据迁移
**修复**:
- ✅ 在数据迁移前先删除旧约束
- ✅ 更新数据后重新添加新约束
- ✅ 修复 contract_templates 表的 loan_type 约束
- ✅ 修复 loans 表的 loan_method 约束
- ✅ 修复 customers 表的 loan_method 约束

## 📋 完整字段对应表

### Customer (客户表)
| 前端字段 | 数据库字段 | 类型 | 说明 |
|---------|-----------|------|------|
| id | id | string (UUID) | 主键 |
| customer_code | customer_code | string | 客户代号 |
| customer_number | customer_number | string | 自动生成编号 |
| full_name | name, full_name | string | 姓名 (支持双字段) |
| phone | phone | string | 电话 |
| id_number | id_card, id_number | string | 身份证 (支持双字段) |
| address | address | string | 地址 |
| loan_amount | loan_amount | number | 贷款金额 |
| interest_rate | interest_rate | number | 利息率 |
| loan_method | loan_method | enum | 贷款方式 |
| deposit_amount | deposit_amount | number | 押金金额 |
| received_amount | received_amount | number | 到手金额 |
| suggested_payment | suggested_payment | number | 建议还款 |
| total_repayment | total_repayment | number | 总还款 |
| periods | periods | number | 期数 |
| principal_rate_per_period | principal_rate_per_period | number | 每期本金率 |
| number_of_periods | number_of_periods | number | 总期数 |
| status | status | enum | 客户状态 |
| notes | notes | string | 备注 |
| assigned_to | assigned_to | string (UUID) | 分配给 |
| created_by | created_by | string (UUID) | 创建人 |
| approval_status | approval_status | enum | 审核状态 |
| approved_by | approved_by | string (UUID) | 审核人 |
| approved_at | approved_at | string | 审核时间 |
| contract_signed | contract_signed | boolean | 合同签署 |
| contract_signed_at | contract_signed_at | string | 签署时间 |
| negotiation_terms | negotiation_terms | string | 谈判条件 |
| loss_amount | loss_amount | number | 亏损金额 |
| created_at | created_at | string | 创建时间 |
| updated_at | updated_at | string | 更新时间 |

### Loan (贷款表)
| 前端字段 | 数据库字段 | 类型 | 说明 |
|---------|-----------|------|------|
| id | id | string (UUID) | 主键 |
| customer_id | customer_id | string (UUID) | 客户ID |
| loan_amount | loan_amount | number | 贷款金额 |
| interest_rate | interest_rate | number | 利息率 |
| loan_method | loan_method | enum | 贷款方式 |
| deposit_amount | deposit_amount | number | 押金金额 |
| remaining_principal | remaining_principal | number | 剩余本金 |
| status | status | enum | 贷款状态 |
| issue_date | issue_date | string | 发放日期 |
| due_date | due_date | string | 到期日期 |
| notes | notes | string | 备注 |
| created_at | created_at | string | 创建时间 |
| updated_at | updated_at | string | 更新时间 |

### Repayment (还款记录表)
| 前端字段 | 数据库字段 | 类型 | 说明 |
|---------|-----------|------|------|
| id | id | string (UUID) | 主键 |
| loan_id | loan_id | string (UUID) | 贷款ID |
| customer_id | customer_id | string (UUID) | 客户ID |
| amount | amount | number | 还款金额 |
| principal_amount | principal_amount | number | 本金部分 |
| interest_amount | interest_amount | number | 利息部分 |
| penalty_amount | penalty_amount | number | 罚金部分 |
| excess_amount | excess_amount | number | 多余金额 |
| remaining_principal | remaining_principal | number | 剩余本金 |
| payment_date | payment_date | string | 还款日期 |
| due_date | due_date | string | 应还日期 |
| repayment_type | repayment_type | enum | 还款类型 |
| payment_method | payment_method | enum | 付款方式 |
| receipt_number | receipt_number | string | 收据号 |
| notes | notes | string | 备注 |
| processed_by | processed_by | string (UUID) | 处理人 |
| created_by | created_by | string (UUID) | 创建人 |
| created_at | created_at | string | 创建时间 |

## 🔧 枚举值对应

### 贷款方式 (loan_method)
```typescript
"scenario_a" | "scenario_b" | "scenario_c"
```
- scenario_a: 利息+押金
- scenario_b: 只收利息
- scenario_c: 只收押金

### 客户状态 (status)
```typescript
"normal" | "overdue" | "cleared" | "negotiating" | "bad_debt"
```

### 还款类型 (repayment_type)
```typescript
"interest_only" | "partial_principal" | "full_settlement"
```

### 审核状态 (approval_status)
```typescript
"pending" | "approved" | "rejected"
```

## ✅ 验证通过的功能

1. **客户管理**: 
   - ✅ 添加客户
   - ✅ 编辑客户
   - ✅ 删除客户
   - ✅ 状态更新

2. **数据类型**: 
   - ✅ UUID 主键支持
   - ✅ 字段名兼容性
   - ✅ 枚举值统一

3. **业务逻辑**: 
   - ✅ 贷款计算
   - ✅ 还款分配
   - ✅ 状态流转

## 🚀 下一步操作

运行数据库脚本确保前后端完全同步：
```sql
\i /Users/tonymumu/Desktop/赢天下/loan-management-system/scripts/complete_main_database.sql
```

## 📝 注意事项

1. 数据库同时支持新旧字段名，确保兼容性
2. 所有ID字段已统一为UUID字符串类型
3. 前端组件已更新以支持新的类型定义
4. 枚举值已在前后端保持一致