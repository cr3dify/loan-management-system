/**
 * 报表导出工具函数
 * 支持 PDF 和 Excel 导出
 */

export interface ExportData {
  title: string
  data: any[]
  columns: ExportColumn[]
  summary?: ExportSummary
}

export interface ExportColumn {
  key: string
  label: string
  type: 'string' | 'number' | 'currency' | 'date' | 'percentage'
  width?: number
}

export interface ExportSummary {
  totalAmount?: number
  totalCount?: number
  averageROI?: number
  period?: string
}

/**
 * 导出为 PDF
 */
export async function exportToPDF(exportData: ExportData): Promise<void> {
  try {
    // 动态导入 jsPDF
    const jsPDF = (await import('jspdf')).default
    const { autoTable } = await import('jspdf-autotable')
    
    const doc = new jsPDF()
    
    // 添加标题
    doc.setFontSize(20)
    doc.text(exportData.title, 14, 22)
    
    // 添加生成时间
    doc.setFontSize(10)
    doc.text(`生成时间: ${new Date().toLocaleString('zh-CN')}`, 14, 30)
    
    // 准备表格数据
    const tableData = exportData.data.map(row => 
      exportData.columns.map(col => {
        const value = row[col.key]
        switch (col.type) {
          case 'currency':
            return `RM ${(value || 0).toLocaleString()}`
          case 'date':
            return value ? new Date(value).toLocaleDateString('zh-CN') : ''
          case 'percentage':
            return `${(value || 0).toFixed(1)}%`
          case 'number':
            return (value || 0).toLocaleString()
          default:
            return value || ''
        }
      })
    )
    
    const headers = exportData.columns.map(col => col.label)
    
    // 添加表格
    autoTable(doc, {
      head: [headers],
      body: tableData,
      startY: 40,
      styles: {
        fontSize: 8,
        cellPadding: 3,
      },
      headStyles: {
        fillColor: [66, 139, 202],
        textColor: 255,
        fontStyle: 'bold',
      },
      columnStyles: exportData.columns.reduce((acc, col, index) => {
        acc[index] = { 
          cellWidth: col.width || 'auto',
          halign: col.type === 'number' || col.type === 'currency' ? 'right' : 'left'
        }
        return acc
      }, {} as any),
    })
    
    // 添加汇总信息
    if (exportData.summary) {
      const finalY = (doc as any).lastAutoTable.finalY + 20
      doc.setFontSize(12)
      doc.text('汇总信息', 14, finalY)
      
      let y = finalY + 10
      if (exportData.summary.totalAmount) {
        doc.setFontSize(10)
        doc.text(`总金额: RM ${exportData.summary.totalAmount.toLocaleString()}`, 14, y)
        y += 6
      }
      if (exportData.summary.totalCount) {
        doc.text(`总数量: ${exportData.summary.totalCount}`, 14, y)
        y += 6
      }
      if (exportData.summary.averageROI) {
        doc.text(`平均ROI: ${exportData.summary.averageROI.toFixed(1)}%`, 14, y)
        y += 6
      }
      if (exportData.summary.period) {
        doc.text(`统计期间: ${exportData.summary.period}`, 14, y)
      }
    }
    
    // 保存文件
    const fileName = `${exportData.title}_${new Date().toISOString().split('T')[0]}.pdf`
    doc.save(fileName)
    
  } catch (error) {
    console.error('PDF导出失败:', error)
    throw new Error('PDF导出功能需要安装 jspdf 和 jspdf-autotable 包')
  }
}

/**
 * 导出为 Excel
 */
export async function exportToExcel(exportData: ExportData): Promise<void> {
  try {
    // 动态导入 xlsx
    const XLSX = await import('xlsx')
    
    // 准备数据
    const worksheetData = [
      // 标题行
      exportData.columns.map(col => col.label),
      // 数据行
      ...exportData.data.map(row => 
        exportData.columns.map(col => {
          const value = row[col.key]
          switch (col.type) {
            case 'currency':
              return value || 0
            case 'date':
              return value ? new Date(value) : null
            case 'percentage':
              return (value || 0) / 100
            case 'number':
              return value || 0
            default:
              return value || ''
          }
        })
      )
    ]
    
    // 创建工作表
    const worksheet = XLSX.utils.aoa_to_sheet(worksheetData)
    
    // 设置列宽
    const colWidths = exportData.columns.map(col => ({ wch: col.width || 15 }))
    worksheet['!cols'] = colWidths
    
    // 创建工作簿
    const workbook = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(workbook, worksheet, '数据')
    
    // 添加汇总信息工作表
    if (exportData.summary) {
      const summaryData = [
        ['汇总信息', ''],
        ['生成时间', new Date().toLocaleString('zh-CN')],
        ['统计期间', exportData.summary.period || ''],
        ['', ''],
        ['指标', '数值'],
        ['总金额', exportData.summary.totalAmount || 0],
        ['总数量', exportData.summary.totalCount || 0],
        ['平均ROI', exportData.summary.averageROI || 0],
      ]
      
      const summarySheet = XLSX.utils.aoa_to_sheet(summaryData)
      XLSX.utils.book_append_sheet(workbook, summarySheet, '汇总')
    }
    
    // 保存文件
    const fileName = `${exportData.title}_${new Date().toISOString().split('T')[0]}.xlsx`
    XLSX.writeFile(workbook, fileName)
    
  } catch (error) {
    console.error('Excel导出失败:', error)
    throw new Error('Excel导出功能需要安装 xlsx 包')
  }
}

/**
 * 导出客户数据
 */
export function exportCustomerData(customers: any[]): ExportData {
  return {
    title: '客户数据报表',
    data: customers,
    columns: [
      { key: 'customer_code', label: '客户代号', type: 'string' },
      { key: 'full_name', label: '客户姓名', type: 'string' },
      { key: 'phone', label: '电话', type: 'string' },
      { key: 'loan_amount', label: '贷款金额', type: 'currency' },
      { key: 'interest_rate', label: '利率', type: 'percentage' },
      { key: 'status', label: '状态', type: 'string' },
      { key: 'approval_status', label: '审批状态', type: 'string' },
      { key: 'created_at', label: '创建时间', type: 'date' },
    ],
    summary: {
      totalAmount: customers.reduce((sum, c) => sum + (c.loan_amount || 0), 0),
      totalCount: customers.length,
      period: new Date().toLocaleDateString('zh-CN')
    }
  }
}

/**
 * 导出还款数据
 */
export function exportRepaymentData(repayments: any[]): ExportData {
  return {
    title: '还款数据报表',
    data: repayments,
    columns: [
      { key: 'customer_name', label: '客户姓名', type: 'string' },
      { key: 'amount', label: '还款金额', type: 'currency' },
      { key: 'principal_amount', label: '本金', type: 'currency' },
      { key: 'interest_amount', label: '利息', type: 'currency' },
      { key: 'penalty_amount', label: '罚金', type: 'currency' },
      { key: 'repayment_type', label: '还款类型', type: 'string' },
      { key: 'payment_date', label: '还款日期', type: 'date' },
    ],
    summary: {
      totalAmount: repayments.reduce((sum, r) => sum + (r.amount || 0), 0),
      totalCount: repayments.length,
      period: new Date().toLocaleDateString('zh-CN')
    }
  }
}

/**
 * 导出费用数据
 */
export function exportExpenseData(expenses: any[]): ExportData {
  return {
    title: '费用数据报表',
    data: expenses,
    columns: [
      { key: 'employee_name', label: '员工姓名', type: 'string' },
      { key: 'expense_type_name', label: '费用类型', type: 'string' },
      { key: 'amount', label: '金额', type: 'currency' },
      { key: 'description', label: '描述', type: 'string' },
      { key: 'expense_date', label: '费用日期', type: 'date' },
      { key: 'approval_status', label: '审批状态', type: 'string' },
    ],
    summary: {
      totalAmount: expenses.reduce((sum, e) => sum + (e.amount || 0), 0),
      totalCount: expenses.length,
      period: new Date().toLocaleDateString('zh-CN')
    }
  }
}

/**
 * 导出员工盈亏数据
 */
export function exportEmployeeProfitData(profits: any[]): ExportData {
  return {
    title: '员工盈亏报表',
    data: profits,
    columns: [
      { key: 'employee_name', label: '员工姓名', type: 'string' },
      { key: 'total_loans', label: '放款总额', type: 'currency' },
      { key: 'total_repayments', label: '回款总额', type: 'currency' },
      { key: 'total_expenses', label: '总费用', type: 'currency' },
      { key: 'net_profit', label: '净利润', type: 'currency' },
      { key: 'roi_percentage', label: 'ROI', type: 'percentage' },
      { key: 'period_year', label: '年份', type: 'number' },
      { key: 'period_month', label: '月份', type: 'number' },
    ],
    summary: {
      totalAmount: profits.reduce((sum, p) => sum + (p.net_profit || 0), 0),
      totalCount: profits.length,
      averageROI: profits.length > 0 ? profits.reduce((sum, p) => sum + (p.roi_percentage || 0), 0) / profits.length : 0,
      period: new Date().toLocaleDateString('zh-CN')
    }
  }
}
