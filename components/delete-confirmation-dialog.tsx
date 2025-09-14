"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { AlertTriangle, Trash2 } from "lucide-react"

interface DeleteConfirmationDialogProps {
  isOpen: boolean
  onClose: () => void
  onConfirm: () => Promise<void>
  customerName: string
  customerCode: string
  isLoading?: boolean
}

export function DeleteConfirmationDialog({
  isOpen,
  onClose,
  onConfirm,
  customerName,
  customerCode,
  isLoading = false
}: DeleteConfirmationDialogProps) {
  const [isDeleting, setIsDeleting] = useState(false)

  const handleConfirm = async () => {
    setIsDeleting(true)
    try {
      await onConfirm()
      onClose()
    } catch (error) {
      console.error("删除失败:", error)
    } finally {
      setIsDeleting(false)
    }
  }

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <div className="flex items-center space-x-2">
            <AlertTriangle className="w-5 h-5 text-red-500" />
            <DialogTitle>确认删除客户</DialogTitle>
          </div>
          <DialogDescription className="pt-2">
            您确定要删除客户 <strong>{customerName}</strong> ({customerCode}) 吗？
            <br />
            <br />
            <span className="text-red-600 font-medium">
              此操作将永久删除客户的所有数据，包括：
            </span>
            <ul className="list-disc list-inside mt-2 text-sm text-gray-600">
              <li>客户基本信息</li>
              <li>贷款记录</li>
              <li>还款记录</li>
              <li>相关合同</li>
            </ul>
            <br />
            <span className="text-red-600 font-medium">此操作无法撤销！</span>
          </DialogDescription>
        </DialogHeader>
        <DialogFooter className="flex-col sm:flex-row gap-2">
          <Button
            variant="outline"
            onClick={onClose}
            disabled={isDeleting || isLoading}
            className="w-full sm:w-auto"
          >
            取消
          </Button>
          <Button
            variant="destructive"
            onClick={handleConfirm}
            disabled={isDeleting || isLoading}
            className="w-full sm:w-auto"
          >
            {isDeleting ? (
              <>
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
                删除中...
              </>
            ) : (
              <>
                <Trash2 className="w-4 h-4 mr-2" />
                确认删除
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

