"use client"

import { useState, useEffect } from "react"
import { createClient } from "@/lib/supabase/client"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Settings, Save, RefreshCw } from "lucide-react"

interface SystemSetting {
  id: number
  setting_key: string
  setting_value: string
  setting_type: string
  description: string
  is_editable: boolean
}

export function SystemSettings() {
  const [settings, setSettings] = useState<SystemSetting[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const supabase = createClient()

  useEffect(() => {
    fetchSettings()
  }, [])

  const fetchSettings = async () => {
    try {
      const { data, error } = await supabase.from("system_settings").select("*").order("setting_key")

      if (error) throw error
      setSettings(data || [])
    } catch (error) {
      console.error("获取系统设置失败:", error)
    } finally {
      setLoading(false)
    }
  }

  const handleSettingChange = (key: string, value: string) => {
    setSettings((prev) =>
      prev.map((setting) => (setting.setting_key === key ? { ...setting, setting_value: value } : setting)),
    )
  }

  const handleSave = async () => {
    setSaving(true)
    try {
      const updates = settings.map((setting) => ({
        id: setting.id,
        setting_value: setting.setting_value,
      }))

      for (const update of updates) {
        const { error } = await supabase
          .from("system_settings")
          .update({ setting_value: update.setting_value })
          .eq("id", update.id)

        if (error) throw error
      }

      alert("设置保存成功")
    } catch (error) {
      console.error("保存设置失败:", error)
      alert("保存失败，请重试")
    } finally {
      setSaving(false)
    }
  }

  const renderSettingInput = (setting: SystemSetting) => {
    if (!setting.is_editable) {
      return <Input value={setting.setting_value} disabled className="bg-muted" />
    }

    switch (setting.setting_type) {
      case "number":
        return (
          <Input
            type="number"
            step="0.01"
            value={setting.setting_value}
            onChange={(e) => handleSettingChange(setting.setting_key, e.target.value)}
          />
        )
      case "boolean":
        return (
          <select
            value={setting.setting_value}
            onChange={(e) => handleSettingChange(setting.setting_key, e.target.value)}
            className="w-full px-3 py-2 border border-border rounded-md bg-input"
          >
            <option value="true">是</option>
            <option value="false">否</option>
          </select>
        )
      default:
        return (
          <Input
            value={setting.setting_value}
            onChange={(e) => handleSettingChange(setting.setting_key, e.target.value)}
          />
        )
    }
  }

  return (
    <main className="container mx-auto px-4 py-8">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold text-foreground mb-2">系统设置</h1>
            <p className="text-muted-foreground">管理系统参数和配置</p>
          </div>
          <div className="flex items-center space-x-4">
            <Button variant="outline" onClick={fetchSettings} disabled={loading}>
              <RefreshCw className={`w-4 h-4 mr-2 ${loading ? "animate-spin" : ""}`} />
              刷新
            </Button>
            <Button
              onClick={handleSave}
              disabled={saving}
              className="bg-primary hover:bg-primary/90 text-primary-foreground"
            >
              <Save className="w-4 h-4 mr-2" />
              {saving ? "保存中..." : "保存设置"}
            </Button>
          </div>
        </div>

        {loading ? (
          <Card>
            <CardContent className="p-8">
              <div className="flex items-center justify-center">
                <RefreshCw className="w-6 h-6 animate-spin text-primary mr-2" />
                <span className="text-muted-foreground">加载中...</span>
              </div>
            </CardContent>
          </Card>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* 基础设置 */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Settings className="w-5 h-5 text-primary" />
                  <span>基础设置</span>
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                {settings
                  .filter((s) => ["company_name", "currency_symbol", "default_penalty_rate"].includes(s.setting_key))
                  .map((setting) => (
                    <div key={setting.id}>
                      <Label htmlFor={setting.setting_key}>{setting.description}</Label>
                      {renderSettingInput(setting)}
                    </div>
                  ))}
              </CardContent>
            </Card>

            {/* 贷款设置 */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Settings className="w-5 h-5 text-primary" />
                  <span>贷款设置</span>
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                {settings
                  .filter((s) =>
                    ["max_loan_amount", "min_loan_amount", "default_periods", "default_principal_rate"].includes(
                      s.setting_key,
                    ),
                  )
                  .map((setting) => (
                    <div key={setting.id}>
                      <Label htmlFor={setting.setting_key}>{setting.description}</Label>
                      {renderSettingInput(setting)}
                    </div>
                  ))}
              </CardContent>
            </Card>
          </div>
        )}

        {/* 系统信息 */}
        <Card className="mt-8">
          <CardHeader>
            <CardTitle>系统信息</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div>
                <div className="text-muted-foreground">系统版本</div>
                <div className="font-medium">v1.0.0</div>
              </div>
              <div>
                <div className="text-muted-foreground">数据库状态</div>
                <div className="font-medium text-green-600">正常</div>
              </div>
              <div>
                <div className="text-muted-foreground">最后更新</div>
                <div className="font-medium">{new Date().toLocaleDateString("zh-CN")}</div>
              </div>
            </div>
          </CardContent>
        </Card>
    </main>
  )
}
