import { RepaymentManagement } from "@/components/repayment-management"
import { ProtectedRoute } from "@/components/protected-route"
import { DashboardLayout } from "@/components/dashboard-layout"

export default function RepaymentsPage() {
  return (
    <ProtectedRoute>
      <DashboardLayout>
        <RepaymentManagement />
      </DashboardLayout>
    </ProtectedRoute>
  )
}
