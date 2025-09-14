"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Check, X, Edit } from "lucide-react"
import { useCanEditField } from "@/hooks/use-permissions"

interface InlineEditProps {
  value: string
  options: { value: string; label: string }[]
  onSave: (newValue: string) => Promise<void>
  disabled?: boolean
  className?: string
  fieldName?: string // 用于权限检查
}

export function InlineEdit({ value, options, onSave, disabled = false, className = "", fieldName }: InlineEditProps) {
  const [isEditing, setIsEditing] = useState(false)
  const [editValue, setEditValue] = useState(value)
  const [saving, setSaving] = useState(false)
  
  // 权限检查
  const canEdit = useCanEditField(fieldName || "")
  const isDisabled = disabled || !canEdit

  useEffect(() => {
    setEditValue(value)
  }, [value])

  const handleSave = async () => {
    if (editValue === value) {
      setIsEditing(false)
      return
    }

    setSaving(true)
    try {
      await onSave(editValue)
      setIsEditing(false)
    } catch (error) {
      console.error("保存失败:", error)
      // 恢复原值
      setEditValue(value)
    } finally {
      setSaving(false)
    }
  }

  const handleCancel = () => {
    setEditValue(value)
    setIsEditing(false)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") {
      handleSave()
    } else if (e.key === "Escape") {
      handleCancel()
    }
  }

  if (isDisabled) {
    const option = options.find(opt => opt.value === value)
    return (
      <div className={`flex items-center space-x-1 ${className}`}>
        <span>{option?.label || value}</span>
        {!canEdit && (
          <span className="text-xs text-muted-foreground ml-2">(无编辑权限)</span>
        )}
      </div>
    )
  }

  if (isEditing) {
    return (
      <div className={`flex items-center space-x-1 ${className}`}>
        <Select
          value={editValue}
          onValueChange={setEditValue}
        >
          <SelectTrigger className="h-8 w-32 bg-white border-gray-300 text-gray-900">
            <SelectValue />
          </SelectTrigger>
          <SelectContent className="bg-white border border-gray-200 shadow-lg z-50">
            {options.map((option) => (
              <SelectItem 
                key={option.value} 
                value={option.value}
                className="text-gray-900 hover:bg-gray-100 focus:bg-gray-100 cursor-pointer"
              >
                {option.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Button
          size="sm"
          variant="ghost"
          onClick={handleSave}
          disabled={saving}
          className="h-8 w-8 p-0 text-green-600 hover:text-green-700"
        >
          <Check className="w-4 h-4" />
        </Button>
        <Button
          size="sm"
          variant="ghost"
          onClick={handleCancel}
          disabled={saving}
          className="h-8 w-8 p-0 text-red-600 hover:text-red-700"
        >
          <X className="w-4 h-4" />
        </Button>
      </div>
    )
  }

  const option = options.find(opt => opt.value === value)
  return (
    <div className={`flex items-center space-x-1 group ${className}`}>
      <span>{option?.label || value}</span>
      <Button
        size="sm"
        variant="ghost"
        onClick={() => setIsEditing(true)}
        className="h-6 w-6 p-0 opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <Edit className="w-3 h-3" />
      </Button>
    </div>
  )
}