#!/bin/bash

# Phase 2 导出功能依赖安装脚本
echo "🚀 安装 Phase 2 导出功能依赖..."

# 安装 PDF 导出依赖
echo "📄 安装 PDF 导出依赖..."
npm install jspdf jspdf-autotable

# 安装 Excel 导出依赖
echo "📊 安装 Excel 导出依赖..."
npm install xlsx

# 安装类型定义
echo "🔧 安装类型定义..."
npm install --save-dev @types/jspdf

echo "✅ 依赖安装完成！"
echo ""
echo "📋 已安装的包："
echo "  - jspdf: PDF 生成"
echo "  - jspdf-autotable: PDF 表格"
echo "  - xlsx: Excel 文件处理"
echo "  - @types/jspdf: TypeScript 类型定义"
echo ""
echo "🎉 Phase 2 导出功能已准备就绪！"
