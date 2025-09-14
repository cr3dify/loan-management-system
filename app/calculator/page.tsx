import { LoanCalculatorPage } from "@/components/loan-calculator-page"
import { ProtectedRoute } from "@/components/protected-route"
import { DashboardLayout } from "@/components/dashboard-layout"

export default function CalculatorPage() {
  return (
    <ProtectedRoute>
      <DashboardLayout>
        <LoanCalculatorPage />
      </DashboardLayout>
    </ProtectedRoute>
  )
}
