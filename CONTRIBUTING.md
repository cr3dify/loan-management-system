# 🤝 贡献指南

感谢您考虑为贷款管理系统项目做出贡献！我们欢迎所有形式的贡献，包括但不限于：

- 🐛 报告 bug
- 💡 提出新功能建议
- 📝 改进文档
- 🔧 提交代码修复
- 🎨 改进用户界面

## 🚀 开始贡献

### 1. Fork 和克隆

```bash
# Fork 本仓库到你的 GitHub 账户
# 然后克隆你的 Fork
git clone https://github.com/your-username/loan-management-system.git
cd loan-management-system

# 添加上游仓库
git remote add upstream https://github.com/original-username/loan-management-system.git
```

### 2. 设置开发环境

```bash
# 安装依赖
npm install

# 复制环境变量文件
cp .env.example .env.local

# 编辑 .env.local 文件，填入你的 Supabase 配置
```

### 3. 创建功能分支

```bash
# 从 main 分支创建新分支
git checkout -b feature/your-feature-name

# 或者修复 bug
git checkout -b fix/bug-description
```

## 📝 开发规范

### 代码风格

- 使用 TypeScript 编写所有新代码
- 遵循 ESLint 和 Prettier 配置
- 使用有意义的变量和函数名
- 添加适当的注释

### 提交信息

使用清晰的提交信息：

```bash
# 好的提交信息
git commit -m "feat: 添加客户搜索功能"
git commit -m "fix: 修复还款计算错误"
git commit -m "docs: 更新 API 文档"

# 避免的提交信息
git commit -m "修复了一些东西"
git commit -m "更新"
```

### 提交类型

- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 添加测试
- `chore`: 构建过程或辅助工具的变动

## 🔄 提交流程

### 1. 保持分支同步

```bash
# 获取最新的上游更改
git fetch upstream
git checkout main
git merge upstream/main

# 更新你的功能分支
git checkout feature/your-feature-name
git merge main
```

### 2. 提交更改

```bash
# 添加更改
git add .

# 提交更改
git commit -m "描述你的更改"

# 推送到你的 Fork
git push origin feature/your-feature-name
```

### 3. 创建 Pull Request

1. 在 GitHub 上创建 Pull Request
2. 填写详细的描述
3. 链接相关的 Issue（如果有）
4. 等待代码审查

## 🐛 报告问题

### 创建 Issue 前

1. 搜索现有的 Issues 确认问题未被报告
2. 检查是否是最新版本的问题
3. 尝试重现问题

### Issue 模板

使用以下模板创建 Issue：

```markdown
## 问题描述
简要描述问题

## 重现步骤
1. 进入 '...'
2. 点击 '...'
3. 滚动到 '...'
4. 看到错误

## 预期行为
描述你期望发生的事情

## 实际行为
描述实际发生的事情

## 环境信息
- 操作系统: [e.g. Windows 10, macOS 12.0]
- 浏览器: [e.g. Chrome 91, Firefox 89]
- 项目版本: [e.g. v1.0.0]

## 截图
如果适用，添加截图帮助解释问题

## 额外信息
添加任何其他关于问题的信息
```

## 💡 功能建议

### 提出新功能

1. 检查现有的功能请求
2. 详细描述功能需求
3. 解释为什么这个功能有用
4. 提供可能的实现方案

### 功能请求模板

```markdown
## 功能描述
简要描述你希望添加的功能

## 问题背景
描述这个功能要解决什么问题

## 解决方案
详细描述你建议的解决方案

## 替代方案
描述你考虑过的其他解决方案

## 额外信息
添加任何其他相关信息
```

## 🔍 代码审查

### 审查者指南

- 检查代码质量和风格
- 确保功能按预期工作
- 验证测试覆盖
- 提供建设性反馈

### 被审查者指南

- 及时响应审查意见
- 解释你的设计决策
- 根据反馈进行修改
- 保持积极的态度

## 📚 开发资源

### 有用的链接

- [Next.js 文档](https://nextjs.org/docs)
- [React 文档](https://reactjs.org/docs)
- [TypeScript 文档](https://www.typescriptlang.org/docs)
- [Supabase 文档](https://supabase.com/docs)
- [Tailwind CSS 文档](https://tailwindcss.com/docs)

### 项目结构

```
src/
├── app/                 # Next.js App Router
├── components/          # React 组件
├── lib/                # 工具函数和配置
├── hooks/              # 自定义 Hooks
└── types/              # TypeScript 类型定义
```

## 🎉 贡献者

感谢所有为这个项目做出贡献的开发者！

<!-- 这里会自动更新贡献者列表 -->

## 📞 获取帮助

如果你在贡献过程中遇到问题：

1. 查看 [Issues](https://github.com/your-username/loan-management-system/issues)
2. 在 Discussions 中提问
3. 联系维护者

---

**再次感谢你的贡献！** 🚀

