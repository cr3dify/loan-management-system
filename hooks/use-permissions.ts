import { useAuth } from "@/components/auth-provider"
import { useMemo } from "react"

export type UserRole = "admin" | "secretary" | "employee" | "super_admin"

export interface PermissionRules {
  canEditCustomerStatus: boolean
  canDeleteCustomer: boolean
  canEditAllFields: boolean
  canViewReports: boolean
  canManageUsers: boolean
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
    }

    switch (effectiveRole) {
      case "super_admin":
      case "admin":
        // 管理员和超级管理员拥有所有权限
        rules.canEditCustomerStatus = true
        rules.canDeleteCustomer = true
        rules.canEditAllFields = true
        rules.canViewReports = true
        rules.canManageUsers = true
        break

      case "secretary":
        // 秘书拥有大部分权限，但不能删除客户
        rules.canEditCustomerStatus = true
        rules.canDeleteCustomer = false
        rules.canEditAllFields = true
        rules.canViewReports = true
        rules.canManageUsers = false
        break

      case "employee":
        // 员工以上（包括员工）可以编辑客户状态
        rules.canEditCustomerStatus = true
        rules.canDeleteCustomer = false
        rules.canEditAllFields = false
        rules.canViewReports = false
        rules.canManageUsers = false
        break

      default:
        // 默认无权限
        break
    }

    return {
      ...rules,
      userRole: effectiveRole,
      isEmployee: ["employee", "secretary", "admin", "super_admin"].includes(effectiveRole)
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