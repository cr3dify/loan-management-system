"use client"

import { useState } from "react"
import { LoanCalculator, type LoanCalculationParams, type LoanCalculationResult } from "@/lib/loan-calculator"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Calculator, TrendingUp, DollarSign, Calendar, AlertCircle } from "lucide-react"

export function LoanCalculatorPage() {
  const [params, setParams] = useState<LoanCalculationParams>({
    loanAmount: 10000,
    interestRate: 10,
    loanMethod: "scenario_a",
    depositAmount: 1000,
    numberOfPeriods: 10,
    principalRatePerPeriod: 10,
  })

  const [result, setResult] = useState<LoanCalculationResult | null>(null)
  const [errors, setErrors] = useState<string[]>([])

  const handleCalculate = () => {
    const validationErrors = LoanCalculator.validateParams(params)

    if (validationErrors.length > 0) {
      setErrors(validationErrors)
      setResult(null)
      return
    }

    setErrors([])
    const calculationResult = LoanCalculator.calculate(params)
    setResult(calculationResult)
  }

  const handleParamChange = (key: keyof LoanCalculationParams, value: string | number) => {
    setParams((prev) => ({
      ...prev,
      [key]: typeof value === "string" ? Number.parseFloat(value) || 0 : value,
    }))
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-foreground mb-2">贷款计算器</h1>
        <p className="text-muted-foreground">精确计算贷款利息、还款计划和投资回报</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* 参数输入 */}
        <div className="lg:col-span-1">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <Calculator className="w-5 h-5 text-primary" />
                <span>计算参数</span>
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label htmlFor="loanAmount">贷款金额 (RM)</Label>
                <Input
                  id="loanAmount"
                  type="number"
                  step="0.01"
                  value={params.loanAmount}
                  onChange={(e) => handleParamChange("loanAmount", e.target.value)}
                />
              </div>

              <div>
                <Label htmlFor="interestRate">利息比例 (%)</Label>
                <Input
                  id="interestRate"
                  type="number"
                  step="0.01"
                  value={params.interestRate}
                  onChange={(e) => handleParamChange("interestRate", e.target.value)}
                />
              </div>

              <div>
                <Label htmlFor="loanMethod">贷款模式</Label>
                <select
                  id="loanMethod"
                  value={params.loanMethod}
                  onChange={(e) => handleParamChange("loanMethod", e.target.value as "scenario_a" | "scenario_b" | "scenario_c")}
                  className="w-full px-3 py-2 border border-border rounded-md bg-input"
                >
                  <option value="scenario_a">场景A：利息+押金</option>
                  <option value="scenario_b">场景B：只收利息</option>
                  <option value="scenario_c">场景C：只收押金</option>
                </select>
              </div>

              <div>
                <Label htmlFor="depositAmount">抵押金额 (RM)</Label>
                <Input
                  id="depositAmount"
                  type="number"
                  step="0.01"
                  value={params.depositAmount}
                  onChange={(e) => handleParamChange("depositAmount", e.target.value)}
                />
              </div>

              <div>
                <Label htmlFor="numberOfPeriods">还款期数</Label>
                <Input
                  id="numberOfPeriods"
                  type="number"
                  value={params.numberOfPeriods}
                  onChange={(e) => handleParamChange("numberOfPeriods", e.target.value)}
                />
              </div>

              <div>
                <Label htmlFor="principalRatePerPeriod">每期本金比例 (%)</Label>
                <Input
                  id="principalRatePerPeriod"
                  type="number"
                  step="0.01"
                  value={params.principalRatePerPeriod}
                  onChange={(e) => handleParamChange("principalRatePerPeriod", e.target.value)}
                />
              </div>

              <Button
                onClick={handleCalculate}
                className="w-full bg-primary hover:bg-primary/90 text-primary-foreground"
              >
                <Calculator className="w-4 h-4 mr-2" />
                计算贷款
              </Button>

              {errors.length > 0 && (
                <div className="space-y-2">
                  {errors.map((error, index) => (
                    <div key={index} className="flex items-center space-x-2 text-destructive text-sm">
                      <AlertCircle className="w-4 h-4" />
                      <span>{error}</span>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* 计算结果 */}
        <div className="lg:col-span-2">
          {result ? (
            <div className="space-y-6">
              {/* 基础结果 */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center space-x-2">
                    <DollarSign className="w-5 h-5 text-primary" />
                    <span>计算结果</span>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="text-center">
                      <div className="text-2xl font-bold text-primary">RM {result.receivedAmount.toLocaleString()}</div>
                      <div className="text-sm text-muted-foreground">到手现金</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-secondary">RM {result.interest.toLocaleString()}</div>
                      <div className="text-sm text-muted-foreground">利息金额</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-accent">
                        RM {result.suggestedPayment.toLocaleString()}
                      </div>
                      <div className="text-sm text-muted-foreground">建议每期还款</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-foreground">
                        RM {result.totalRepayment.toLocaleString()}
                      </div>
                      <div className="text-sm text-muted-foreground">总还款金额</div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* 投资分析 */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center space-x-2">
                    <TrendingUp className="w-5 h-5 text-primary" />
                    <span>投资分析</span>
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="text-center">
                      <div className="text-xl font-bold text-green-600">
                        {result.summary.effectiveInterestRate.toFixed(2)}%
                      </div>
                      <div className="text-sm text-muted-foreground">实际利率</div>
                    </div>
                    <div className="text-center">
                      <div className="text-xl font-bold text-blue-600">
                        {result.summary.returnOnInvestment.toFixed(2)}%
                      </div>
                      <div className="text-sm text-muted-foreground">投资回报率</div>
                    </div>
                    <div className="text-center">
                      <div className="text-xl font-bold text-purple-600">
                        RM {result.summary.totalInterest.toLocaleString()}
                      </div>
                      <div className="text-sm text-muted-foreground">总利息收入</div>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* 还款计划 */}
              {result.paymentSchedule.length > 0 && (
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center space-x-2">
                      <Calendar className="w-5 h-5 text-primary" />
                      <span>还款计划表</span>
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="overflow-x-auto">
                      <table className="w-full">
                        <thead>
                          <tr className="border-b border-border">
                            <th className="text-left py-2 px-4 font-medium text-muted-foreground">期数</th>
                            <th className="text-left py-2 px-4 font-medium text-muted-foreground">本金</th>
                            <th className="text-left py-2 px-4 font-medium text-muted-foreground">利息</th>
                            <th className="text-left py-2 px-4 font-medium text-muted-foreground">合计</th>
                            <th className="text-left py-2 px-4 font-medium text-muted-foreground">剩余本金</th>
                          </tr>
                        </thead>
                        <tbody>
                          {result.paymentSchedule.map((item) => (
                            <tr key={item.period} className="border-b border-border hover:bg-muted/50">
                              <td className="py-2 px-4 font-medium">第 {item.period} 期</td>
                              <td className="py-2 px-4">RM {item.principalPayment.toLocaleString()}</td>
                              <td className="py-2 px-4">RM {item.interestPayment.toLocaleString()}</td>
                              <td className="py-2 px-4 font-medium">RM {item.totalPayment.toLocaleString()}</td>
                              <td className="py-2 px-4">
                                {item.remainingPrincipal > 0 ? (
                                  `RM ${item.remainingPrincipal.toLocaleString()}`
                                ) : (
                                  <Badge className="bg-green-100 text-green-800">已结清</Badge>
                                )}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>
          ) : (
            <Card>
              <CardContent className="p-8 text-center">
                <Calculator className="w-16 h-16 text-muted-foreground mx-auto mb-4" />
                <h3 className="text-lg font-medium text-muted-foreground mb-2">请输入计算参数</h3>
                <p className="text-muted-foreground">填写左侧的贷款参数，然后点击"计算贷款"按钮查看详细结果</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}
