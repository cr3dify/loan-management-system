import { useAuth } from "@/components/auth-provider"
import { useMemo } from "react"

export type UserRole = "admin" | "secretary" | "employee"

export interface PermissionRules {
  canEditCustomerStatus: boolean
  canDeleteCustomer: boolean
  canEditAllFields: boolean
  canViewReports: boolean
  canManageUsers: boolean
  canViewOwnCustomers: boolean
  canViewAllCustomers: boolean
  canManageExpenses: boolean
  canApproveRecords: boolean
  canViewTeamPerformance: boolean
  canAssignCustomers: boolean
}

/**
 * 权限管理Hook
 * 根据用户角色返回权限规则
 */
export function usePermissions(): PermissionRules & { userRole: UserRole | null; isEmployee: boolean } {
  const { user } = useAuth()

  const permissions = useMemo(() => {
    // 从多个来源获取角色信息，优先级：app_metadata > user_metadata > 默认
    const userRole = (
      user?.app_metadata?.role || 
      user?.user_metadata?.role || 
      "employee"
    ) as UserRole

    // 如果用户是超级管理员，直接给予管理员权限
    const isSuperAdmin = (user as any)?.is_super_admin === true || 
                        user?.app_metadata?.role === "super_admin"
    const effectiveRole = isSuperAdmin ? "admin" : userRole

    // 生产环境已移除调试信息

    const rules: PermissionRules = {
      canEditCustomerStatus: false,
      canDeleteCustomer: false,
      canEditAllFields: false,
      canViewReports: false,
      canManageUsers: false,
      canViewOwnCustomers: false,
      canViewAllCustomers: false,
      canManageExpenses: false,
      canApproveRecords: false,
      canViewTeamPerformance: false,
      canAssignCustomers: false,
    }

    switch (effectiveRole) {
      case "admin":
        // 管理员拥有所有权限
        rules.canEditCustomerStatus = true
        rules.canDeleteCustomer = true
        rules.canEditAllFields = true
        rules.canViewReports = true
        rules.canManageUsers = true
        rules.canViewOwnCustomers = true
        rules.canViewAllCustomers = true
        rules.canManageExpenses = true
        rules.canApproveRecords = true
        rules.canViewTeamPerformance = true
        rules.canAssignCustomers = true
        break

      case "secretary":
        // 秘书：审核员工记录、录入费用、搜索所有客户
        rules.canEditCustomerStatus = true
        rules.canDeleteCustomer = false
        rules.canEditAllFields = true
        rules.canViewReports = true
        rules.canManageUsers = false
        rules.canViewOwnCustomers = true
        rules.canViewAllCustomers = true
        rules.canManageExpenses = true
        rules.canApproveRecords = true
        rules.canViewTeamPerformance = false
        rules.canAssignCustomers = true
        break


      case "employee":
        // 员工：仅查看/维护自己客户，提交新客户及还款
        rules.canEditCustomerStatus = true
        rules.canDeleteCustomer = false
        rules.canEditAllFields = false
        rules.canViewReports = false
        rules.canManageUsers = false
        rules.canViewOwnCustomers = true
        rules.canViewAllCustomers = false
        rules.canManageExpenses = true
        rules.canApproveRecords = false
        rules.canViewTeamPerformance = false
        rules.canAssignCustomers = false
        break

      default:
        // 默认无权限
        break
    }

    return {
      ...rules,
      userRole: effectiveRole,
      isEmployee: ["employee", "secretary", "admin"].includes(effectiveRole)
    }
  }, [user])

  return permissions
}

/**
 * 检查是否有编辑特定字段的权限
 */
export function useCanEditField(fieldName: string): boolean {
  const permissions = usePermissions()

  // 状态字段需要员工以上权限
  if (fieldName === "status" || fieldName === "approval_status") {
    return permissions.canEditCustomerStatus
  }

  // 其他字段根据总体权限判断
  return permissions.canEditAllFields
}