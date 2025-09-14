import { CustomerManagement } from "@/components/customer-management"
import { ProtectedRoute } from "@/components/protected-route"
import { DashboardLayout } from "@/components/dashboard-layout"

export default function CustomersPage() {
  return (
    <ProtectedRoute>
      <DashboardLayout>
        <CustomerManagement />
      </DashboardLayout>
    </ProtectedRoute>
  )
}
