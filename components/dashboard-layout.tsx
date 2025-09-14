"use client"

import { Navbar } from "@/components/navbar"

interface DashboardLayoutProps {
  children: React.ReactNode
}

export function DashboardLayout({ children }: DashboardLayoutProps) {
  return (
    <div className="min-h-screen bg-neutral-50">
      <Navbar />
      <main className="flex-1 p-6">
        {children}
      </main>
    </div>
  )
}