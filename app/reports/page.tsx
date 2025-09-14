import { MonthlyLossReport } from "@/components/monthly-loss-report"
import { ProtectedRoute } from "@/components/protected-route"
import { DashboardLayout } from "@/components/dashboard-layout"

export default function ReportsPage() {
  return (
    <ProtectedRoute>
      <DashboardLayout>
        <div className="space-y-6">
          <div>
            <h1 className="text-3xl font-bold text-neutral-900">月度亏损报告</h1>
            <p className="text-neutral-600 mt-2">查看系统自动统计的月度烂账亏损情况</p>
          </div>
          <MonthlyLossReport />
        </div>
      </DashboardLayout>
    </ProtectedRoute>
  )
}
