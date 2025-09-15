export interface LoanCalculationParams {
  loanAmount: number
  interestRate: number
  loanMethod: "scenario_a" | "scenario_b" | "scenario_c"
  depositAmount?: number
  numberOfPeriods?: number
  principalRatePerPeriod?: number
}

export interface LoanCalculationResult {
  // 基础计算
  interest: number
  receivedAmount: number
  targetAmount: number

  // 还款计算
  optimalPeriods: number
  suggestedPayment: number
  totalRepayment: number
  principalPerPeriod: number
  interestPerPeriod: number

  // 详细信息
  paymentSchedule: PaymentScheduleItem[]
  summary: LoanSummary
}

export interface PaymentScheduleItem {
  period: number
  principalPayment: number
  interestPayment: number
  totalPayment: number
  remainingPrincipal: number
}

export interface LoanSummary {
  totalInterest: number
  totalPrincipal: number
  totalPayments: number
}

export class LoanCalculator {
  /**
   * 计算贷款详细信息
   */
  static calculate(params: LoanCalculationParams): LoanCalculationResult {
    const {
      loanAmount,
      interestRate,
      loanMethod,
      depositAmount = 0,
      numberOfPeriods = 0,
      principalRatePerPeriod = 0,
    } = params

    // 基础计算
    const interest = loanAmount * (interestRate / 100)
    let receivedAmount = 0
    let targetAmount = 0
    let suggestedPayment = 0
    let totalRepayment = 0
    let principalPerPeriod = 0
    let interestPerPeriod = 0
    
    // 自动计算最佳还款期数
    const optimalPeriods = this.calculateOptimalPeriods(loanAmount, principalRatePerPeriod)
    const actualNumberOfPeriods = numberOfPeriods || optimalPeriods

    if (loanMethod === "scenario_a") {
      // 场景A：利息+押金（先扣息+押金）
      receivedAmount = loanAmount - interest - depositAmount
      targetAmount = loanAmount

      if (principalRatePerPeriod > 0 && actualNumberOfPeriods > 0) {
        principalPerPeriod = loanAmount * (principalRatePerPeriod / 100)
        interestPerPeriod = interest / actualNumberOfPeriods
        suggestedPayment = principalPerPeriod + interestPerPeriod
        totalRepayment = suggestedPayment * actualNumberOfPeriods - depositAmount
      }
    } else if (loanMethod === "scenario_b") {
      // 场景B：只收利息（先扣息，无押金）
      receivedAmount = loanAmount - interest
      targetAmount = loanAmount

      if (principalRatePerPeriod > 0 && actualNumberOfPeriods > 0) {
        principalPerPeriod = loanAmount * (principalRatePerPeriod / 100)
        interestPerPeriod = interest / actualNumberOfPeriods
        suggestedPayment = principalPerPeriod + interestPerPeriod
        totalRepayment = suggestedPayment * actualNumberOfPeriods
      }
    } else {
      // 场景C：只收押金（无利息，只收押金）
      receivedAmount = loanAmount - depositAmount
      targetAmount = loanAmount

      if (actualNumberOfPeriods > 0) {
        principalPerPeriod = loanAmount / actualNumberOfPeriods
        interestPerPeriod = 0 // 无利息
        suggestedPayment = loanAmount / actualNumberOfPeriods
        totalRepayment = suggestedPayment * actualNumberOfPeriods - depositAmount
      }
    }

    // 生成还款计划
    const paymentSchedule = this.generatePaymentSchedule({
      loanAmount,
      loanMethod,
      principalPerPeriod,
      interestPerPeriod,
      numberOfPeriods: actualNumberOfPeriods,
    })

    // 计算汇总信息
    const summary = this.calculateSummary({
      loanAmount,
      receivedAmount,
      totalRepayment,
      depositAmount,
      paymentSchedule,
    })

    return {
      interest,
      receivedAmount,
      targetAmount,
      optimalPeriods,
      suggestedPayment,
      totalRepayment,
      principalPerPeriod,
      interestPerPeriod,
      paymentSchedule,
      summary,
    }
  }

  /**
   * 生成还款计划表
   */
  private static generatePaymentSchedule(params: {
    loanAmount: number
    loanMethod: "scenario_a" | "scenario_b" | "scenario_c"
    principalPerPeriod: number
    interestPerPeriod: number
    numberOfPeriods: number
  }): PaymentScheduleItem[] {
    const { loanAmount, principalPerPeriod, interestPerPeriod, numberOfPeriods } = params
    const schedule: PaymentScheduleItem[] = []
    let remainingPrincipal = loanAmount

    for (let period = 1; period <= numberOfPeriods; period++) {
      const principalPayment = Math.min(principalPerPeriod, remainingPrincipal)
      const interestPayment = interestPerPeriod
      const totalPayment = principalPayment + interestPayment

      remainingPrincipal -= principalPayment

      schedule.push({
        period,
        principalPayment,
        interestPayment,
        totalPayment,
        remainingPrincipal: Math.max(0, remainingPrincipal),
      })

      if (remainingPrincipal <= 0) break
    }

    return schedule
  }

  /**
   * 计算贷款汇总信息
   */
  private static calculateSummary(params: {
    loanAmount: number
    receivedAmount: number
    totalRepayment: number
    depositAmount: number
    paymentSchedule: PaymentScheduleItem[]
  }): LoanSummary {
    const { loanAmount, receivedAmount, totalRepayment, depositAmount, paymentSchedule } = params

    const totalInterest = paymentSchedule.reduce((sum, item) => sum + item.interestPayment, 0)
    const totalPrincipal = paymentSchedule.reduce((sum, item) => sum + item.principalPayment, 0)
    const totalPayments = paymentSchedule.reduce((sum, item) => sum + item.totalPayment, 0)

    return {
      totalInterest,
      totalPrincipal,
      totalPayments,
    }
  }

  /**
   * 计算逾期罚金
   */
  static calculatePenalty(params: {
    overdueDays: number
    overdueAmount: number
    penaltyRate: number
  }): number {
    const { overdueDays, overdueAmount, penaltyRate } = params
    return overdueAmount * (penaltyRate / 100) * overdueDays
  }

  /**
   * 计算还款分配（本金、利息、罚金）
   */
  static calculateRepaymentAllocation(params: {
    paymentAmount: number
    currentInterest: number
    currentPenalty: number
    remainingPrincipal: number
  }): {
    penaltyPayment: number
    interestPayment: number
    principalPayment: number
    remainingAmount: number
  } {
    const { paymentAmount, currentInterest, currentPenalty, remainingPrincipal } = params

    let remainingAmount = paymentAmount

    // 优先扣除罚金
    const penaltyPayment = Math.min(remainingAmount, currentPenalty)
    remainingAmount -= penaltyPayment

    // 然后扣除利息
    const interestPayment = Math.min(remainingAmount, currentInterest)
    remainingAmount -= interestPayment

    // 最后扣除本金
    const principalPayment = Math.min(remainingAmount, remainingPrincipal)
    remainingAmount -= principalPayment

    return {
      penaltyPayment,
      interestPayment,
      principalPayment,
      remainingAmount,
    }
  }

  /**
   * 验证贷款参数
   */
  static validateParams(params: LoanCalculationParams): string[] {
    const errors: string[] = []

    if (params.loanAmount <= 0) {
      errors.push("贷款金额必须大于0")
    }

    if (params.interestRate < 0 || params.interestRate > 100) {
      errors.push("利息比例必须在0-100%之间")
    }

    if (params.depositAmount && params.depositAmount < 0) {
      errors.push("抵押金额不能为负数")
    }

    if (params.depositAmount && params.depositAmount >= params.loanAmount) {
      errors.push("抵押金额不能大于等于贷款金额")
    }

    if (params.numberOfPeriods && (params.numberOfPeriods < 1 || params.numberOfPeriods > 120)) {
      errors.push("还款期数必须在1-120期之间")
    }

    if (params.principalRatePerPeriod && (params.principalRatePerPeriod < 0 || params.principalRatePerPeriod > 100)) {
      errors.push("每期本金比例必须在0-100%之间")
    }

    return errors
  }

  /**
   * 计算最佳还款期数
   * 基于每期本金比例自动计算合理的还款期数
   */
  private static calculateOptimalPeriods(loanAmount: number, principalRatePerPeriod: number): number {
    if (principalRatePerPeriod <= 0) {
      return 10 // 默认10期
    }
    
    // 根据每期本金比例计算需要多少期才能还完本金
    const periodsNeeded = Math.ceil(100 / principalRatePerPeriod)
    
    // 限制在合理范围内 (3-36期)
    return Math.max(3, Math.min(36, periodsNeeded))
  }
}
