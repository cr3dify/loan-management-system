import { SystemSettings } from "@/components/system-settings"
import { ProtectedRoute } from "@/components/protected-route"
import { DashboardLayout } from "@/components/dashboard-layout"

export default function SettingsPage() {
  return (
    <ProtectedRoute>
      <DashboardLayout>
        <SystemSettings />
      </DashboardLayout>
    </ProtectedRoute>
  )
}
