import { ExpenseManagement } from "@/components/expense-management"
import { DashboardLayout } from "@/components/dashboard-layout"

export default function ExpensesPage() {
  return (
    <DashboardLayout>
      <ExpenseManagement />
    </DashboardLayout>
  )
}
