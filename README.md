# 🏦 贷款管理系统 (Loan Management System)

[![Next.js](https://img.shields.io/badge/Next.js-15-black?style=for-the-badge&logo=next.js)](https://nextjs.org/)
[![React](https://img.shields.io/badge/React-19-blue?style=for-the-badge&logo=react)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0-blue?style=for-the-badge&logo=typescript)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-green?style=for-the-badge&logo=supabase)](https://supabase.com/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css)](https://tailwindcss.com/)

> 一个基于 Next.js 15 和 Supabase 构建的现代化贷款管理系统，专为小额贷款公司设计，提供完整的客户管理、贷款计算、还款跟踪和数据分析功能。

[![Demo](https://img.shields.io/badge/Demo-Live-brightgreen?style=for-the-badge)](https://your-demo-url.com)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=for-the-badge)](http://makeapullrequest.com)

## 📑 目录

- [✨ 主要功能](#-主要功能)
- [🛠️ 技术栈](#️-技术栈)
- [🚀 快速开始](#-快速开始)
- [📁 项目结构](#-项目结构)
- [🔧 配置说明](#-配置说明)
- [📊 功能截图](#-功能截图)
- [🤝 贡献指南](#-贡献指南)
- [📝 更新日志](#-更新日志)
- [📄 许可证](#-许可证)
- [📞 支持](#-支持)
- [🙏 致谢](#-致谢)

## ✨ 主要功能

### 🏠 系统概览

- **实时数据仪表板** - 关键业务指标一目了然
- **客户统计** - 总客户数、活跃贷款、贷款总额等核心数据
- **收入分析** - 月度收入、还款记录统计
- **风险监控** - 逾期客户、已结清客户管理

### 👥 客户管理

- **客户信息管理** - 完整的客户档案系统
- **客户状态跟踪** - 正常、逾期、清完、谈账、烂账等状态管理
- **客户搜索与筛选** - 快速查找特定客户
- **客户代码生成** - 自动生成唯一客户标识

### 💰 贷款管理

- **多种贷款方案** - 支持三种不同的贷款计算方式
- **灵活利率设置** - 可配置的利率和还款周期
- **贷款状态跟踪** - 从申请到结清的完整生命周期
- **合同管理** - 电子合同签署和状态跟踪

### 📊 还款管理

- **还款记录** - 详细的还款历史记录
- **多种还款方式** - 只还利息、部分本金、全额结清
- **逾期管理** - 自动计算逾期天数和罚金
- **还款提醒** - 智能提醒系统

### 🧮 贷款计算器

- **精确计算** - 基于不同贷款方案的精确利息计算
- **还款计划** - 详细的还款计划表
- **多种场景** - 支持三种不同的贷款计算场景
- **实时预览** - 参数调整时实时更新计算结果

### 📈 报表系统

- **月度损失报告** - 详细的损失分析和统计
- **客户分析报告** - 客户行为分析
- **收入报表** - 收入趋势和预测
- **风险报告** - 风险评估和预警

### ⚙️ 系统设置

- **用户权限管理** - 管理员、秘书、经理三级权限
- **系统参数配置** - 可配置的系统参数
- **数据备份** - 自动数据备份和恢复
- **安全设置** - 行级安全策略和访问控制

## 🛠️ 技术栈

### 前端技术

- **Next.js 15** - React 全栈框架
- **React 19** - 用户界面库
- **TypeScript** - 类型安全的 JavaScript
- **Tailwind CSS** - 实用优先的 CSS 框架
- **Radix UI** - 无障碍的 UI 组件库
- **Lucide React** - 现代图标库
- **React Hook Form** - 表单管理
- **Zod** - 数据验证

### 后端技术

- **Supabase** - 开源 Firebase 替代方案
- **PostgreSQL** - 关系型数据库
- **Row Level Security (RLS)** - 行级安全策略
- **Real-time subscriptions** - 实时数据同步

### 开发工具

- **ESLint** - 代码质量检查
- **Prettier** - 代码格式化
- **PostCSS** - CSS 后处理器
- **Vercel Analytics** - 性能监控

## 🚀 快速开始

<div align="center">

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/your-username/loan-management-system)
[![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/your-username/loan-management-system)

</div>

### 📋 环境要求

| 工具 | 版本 | 说明 |
|------|------|------|
| Node.js | 18+ | JavaScript 运行时 |
| npm/yarn | Latest | 包管理器 |
| Supabase | - | 后端服务 |

### ⚡ 一键启动

```bash
# 克隆项目
git clone https://github.com/your-username/loan-management-system.git
cd loan-management-system

# 安装依赖
npm install

# 配置环境变量
cp .env.example .env.local
# 编辑 .env.local 文件，填入你的 Supabase 配置

# 启动开发服务器
npm run dev
```

### 🔧 详细配置

<details>
<summary>点击查看详细配置步骤</summary>

#### 1. 环境变量配置

创建 `.env.local` 文件：

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

#### 2. 数据库设置

1. 在 [Supabase Dashboard](https://app.supabase.com) 创建新项目
2. 在 SQL Editor 中执行 `scripts/quick_database_init.sql`
3. 验证表结构创建成功

#### 3. 启动应用

```bash
npm run dev
```

访问 [http://localhost:3000](http://localhost:3000) 查看应用。

</details>

## 📁 项目结构

```text
loan-management-system/
├── app/                    # Next.js 15 App Router
│   ├── calculator/         # 贷款计算器页面
│   ├── customers/          # 客户管理页面
│   ├── login/             # 登录页面
│   ├── repayments/        # 还款管理页面
│   ├── reports/           # 报表页面
│   └── settings/          # 系统设置页面
├── components/            # React 组件
│   ├── ui/               # 基础 UI 组件
│   ├── dashboard.tsx     # 仪表板组件
│   ├── customer-*.tsx    # 客户相关组件
│   └── repayment-*.tsx   # 还款相关组件
├── lib/                  # 工具库
│   ├── supabase/         # Supabase 客户端配置
│   ├── types.ts          # TypeScript 类型定义
│   └── loan-calculator.ts # 贷款计算逻辑
├── hooks/                # 自定义 React Hooks
├── scripts/              # 数据库脚本
└── docs/                 # 项目文档
```

## 🔧 配置说明

### 数据库配置

系统使用 Supabase 作为后端服务，包含以下核心表：

- `customers` - 客户信息表
- `loans` - 贷款信息表
- `repayments` - 还款记录表
- `users` - 用户管理表
- `system_settings` - 系统设置表

### 权限管理

系统支持三级用户权限：

- **管理员** - 完整系统访问权限
- **经理** - 业务管理权限
- **秘书** - 基础操作权限

### 贷款计算方案

支持三种贷款计算场景：

- **Scenario A** - 标准贷款方案
- **Scenario B** - 灵活还款方案
- **Scenario C** - 特殊业务方案

## 📊 功能截图

<div align="center">

### 🏠 仪表板概览
![Dashboard](https://via.placeholder.com/800x400/4F46E5/FFFFFF?text=Dashboard+Overview)

*实时数据展示，关键指标一目了然*

### 👥 客户管理
![Customer Management](https://via.placeholder.com/800x400/10B981/FFFFFF?text=Customer+Management)

*完整的客户档案管理和状态跟踪*

### 🧮 贷款计算器
![Loan Calculator](https://via.placeholder.com/800x400/F59E0B/FFFFFF?text=Loan+Calculator)

*精确的贷款计算和还款计划*

### 📊 还款管理
![Repayment Management](https://via.placeholder.com/800x400/8B5CF6/FFFFFF?text=Repayment+Management)

*详细的还款记录和逾期管理*

</div>

## 🤝 贡献指南

我们欢迎所有形式的贡献！无论是报告 bug、提出新功能建议，还是提交代码，都非常感谢。

### 🚀 如何贡献

<div align="center">

[![Contributors](https://img.shields.io/github/contributors/your-username/loan-management-system?style=for-the-badge)](https://github.com/your-username/loan-management-system/graphs/contributors)
[![Forks](https://img.shields.io/github/forks/your-username/loan-management-system?style=for-the-badge)](https://github.com/your-username/loan-management-system/network/members)
[![Stars](https://img.shields.io/github/stars/your-username/loan-management-system?style=for-the-badge)](https://github.com/your-username/loan-management-system/stargazers)

</div>

### 📝 贡献步骤

1. **Fork 本仓库** - 点击右上角的 Fork 按钮
2. **克隆你的 Fork** - `git clone https://github.com/your-username/loan-management-system.git`
3. **创建功能分支** - `git checkout -b feature/AmazingFeature`
4. **提交更改** - `git commit -m 'Add some AmazingFeature'`
5. **推送到分支** - `git push origin feature/AmazingFeature`
6. **打开 Pull Request** - 在 GitHub 上创建 PR

### 🐛 报告问题

如果你发现了 bug 或有功能建议，请：

- 查看 [Issues](https://github.com/your-username/loan-management-system/issues) 确认问题未被报告
- 创建新的 Issue，详细描述问题
- 使用合适的标签（bug、enhancement、question 等）

### 💡 代码规范

- 使用 TypeScript 编写代码
- 遵循 ESLint 和 Prettier 配置
- 编写清晰的提交信息
- 为新功能添加测试（如果适用）

## 📝 更新日志

### v1.0.0 (2024-01-XX)

- ✨ 初始版本发布
- 🏠 完整的仪表板功能
- 👥 客户管理系统
- 💰 贷款管理功能
- 📊 还款跟踪系统
- 🧮 贷款计算器
- 📈 报表系统
- ⚙️ 系统设置

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 支持

如果您遇到任何问题或有任何建议，请：

1. 查看 [文档](docs/) 目录
2. 搜索 [Issues](https://github.com/your-username/loan-management-system/issues)
3. 创建新的 Issue
4. 联系维护者

## 📊 项目统计

<div align="center">

![GitHub repo size](https://img.shields.io/github/repo-size/your-username/loan-management-system?style=for-the-badge)
![GitHub language count](https://img.shields.io/github/languages/count/your-username/loan-management-system?style=for-the-badge)
![GitHub top language](https://img.shields.io/github/languages/top/your-username/loan-management-system?style=for-the-badge)
![GitHub last commit](https://img.shields.io/github/last-commit/your-username/loan-management-system?style=for-the-badge)

</div>

## 🙏 致谢

感谢以下优秀的开源项目，让这个项目成为可能：

<table>
<tr>
<td align="center">
<a href="https://nextjs.org/" target="_blank">
<img src="https://raw.githubusercontent.com/vercel/next.js/canary/packages/next/src/static/nextjs-logo.svg" width="50" height="50" alt="Next.js"/>
<br/>
<sub><b>Next.js</b></sub>
</a>
</td>
<td align="center">
<a href="https://supabase.com/" target="_blank">
<img src="https://supabase.com/images/brand/supabase-logo.svg" width="50" height="50" alt="Supabase"/>
<br/>
<sub><b>Supabase</b></sub>
</a>
</td>
<td align="center">
<a href="https://www.radix-ui.com/" target="_blank">
<img src="https://raw.githubusercontent.com/radix-ui/icons/master/packages/radix-icons/icons/accessibility.svg" width="50" height="50" alt="Radix UI"/>
<br/>
<sub><b>Radix UI</b></sub>
</a>
</td>
<td align="center">
<a href="https://tailwindcss.com/" target="_blank">
<img src="https://raw.githubusercontent.com/tailwindlabs/tailwindcss/HEAD/.github/logo.svg" width="50" height="50" alt="Tailwind CSS"/>
<br/>
<sub><b>Tailwind CSS</b></sub>
</a>
</td>
<td align="center">
<a href="https://lucide.dev/" target="_blank">
<img src="https://lucide.dev/logo.svg" width="50" height="50" alt="Lucide"/>
<br/>
<sub><b>Lucide</b></sub>
</a>
</td>
</tr>
</table>

---

<div align="center">

### ⭐ 如果这个项目对您有帮助，请给我们一个 Star

[![GitHub stars](https://img.shields.io/github/stars/cr3dify/loan-management-system?style=social)](https://github.com/cr3dify/loan-management-system/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/cr3dify/loan-management-system?style=social)](https://github.com/cr3dify/loan-management-system/network/members)

**让更多人发现这个项目！** 🚀

</div>
