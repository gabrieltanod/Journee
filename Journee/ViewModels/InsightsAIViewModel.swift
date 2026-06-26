import Foundation
import SwiftData
import SwiftUI

@Observable
final class InsightsAIViewModel {
    private var modelContext: ModelContext
    private var payday: Int

    var currentCycle: PaydayCycle

    // MARK: - Published State

    var aiAudit: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Cache Key

    /// Unique key per cycle for persisting the audit in UserDefaults.
    private var cacheKey: String {
        "journeeAI_audit_\(currentCycle.label)"
    }

    // MARK: - Init

    init(modelContext: ModelContext, payday: Int = 1) {
        self.modelContext = modelContext
        self.payday = payday
        self.currentCycle = PaydayCycle.cycle(containing: Date(), payday: payday)
        loadCachedAudit()
    }

    // MARK: - Payday Sync

    func updatePayday(_ newPayday: Int) {
        payday = newPayday
        currentCycle = PaydayCycle.cycle(containing: currentCycle.startDate, payday: newPayday)
        errorMessage = nil
        loadCachedAudit()
    }

    func updateCycle(_ cycle: PaydayCycle) {
        currentCycle = cycle
        errorMessage = nil
        loadCachedAudit()
    }

    // MARK: - Persistence

    private func loadCachedAudit() {
        aiAudit = UserDefaults.standard.string(forKey: cacheKey) ?? ""
    }

    private func saveCachedAudit(_ text: String) {
        UserDefaults.standard.set(text, forKey: cacheKey)
    }

    // MARK: - Generate Audit

    func generateAudit(apiKey: String) async {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "API key is missing."
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        let prompt = buildPrompt()

        do {
            let result = try await AIService.generateContent(prompt: prompt, apiKey: apiKey)
            await MainActor.run {
                aiAudit = result
                saveCachedAudit(result)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    // MARK: - Prompt Construction

    private func buildPrompt() -> String {
        let start = currentCycle.fetchStartDate
        let end = currentCycle.fetchEndDate

        // Fetch all transactions in cycle
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= start && $0.date <= end }
        )
        let allItems = (try? modelContext.fetch(descriptor)) ?? []

        let expenseItems = allItems.filter { $0.transactionType == .expense }
        let incomeItems  = allItems.filter { $0.transactionType == .income }

        let totalIncome   = incomeItems.reduce(0.0)  { $0 + $1.amount }
        let totalExpenses = expenseItems.reduce(0.0) { $0 + $1.amount }

        // Fetch budget for this cycle
        let budgetMonth = currentCycle.startMonth
        let budgetYear  = currentCycle.startYear
        let budgetDescriptor = FetchDescriptor<MonthlyBudget>(
            predicate: #Predicate { $0.month == budgetMonth && $0.year == budgetYear }
        )
        let budget = (try? modelContext.fetch(budgetDescriptor))?.first
        let budgetAmount = budget?.amount ?? 0
        let remainingBudget = budgetAmount - totalExpenses

        // Group expenses by HeadCategory (or standalone Category)
        var categoryTotals: [(name: String, amount: Double)] = []
        var grouped: [String: Double] = [:]

        for expense in expenseItems {
            let label: String
            if let headCat = expense.category?.headCategory {
                label = headCat.name
            } else {
                label = expense.category?.name ?? "Uncategorized"
            }
            grouped[label, default: 0] += expense.amount
        }

        categoryTotals = grouped.map { (name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }

        // Build the prompt text with formatted IDR values
        var lines: [String] = []
        lines.append("Cycle: \(currentCycle.label)")
        lines.append("Total Income: \(totalIncome.formattedRupiah)")
        lines.append("Total Expenses: \(totalExpenses.formattedRupiah)")

        if budgetAmount > 0 {
            lines.append("Monthly Budget: \(budgetAmount.formattedRupiah)")
            lines.append("Remaining Budget: \(remainingBudget.formattedRupiah)")
        } else {
            lines.append("Monthly Budget: Not set")
        }

        lines.append("")
        lines.append("Breakdown by Category:")

        if categoryTotals.isEmpty {
            lines.append("- No expenses recorded this cycle.")
        } else {
            for entry in categoryTotals {
                let pct = totalExpenses > 0
                    ? String(format: "%.1f%%", (entry.amount / totalExpenses) * 100)
                    : "0%"
                lines.append("- \(entry.name): \(entry.amount.formattedRupiah) (\(pct))")
            }
        }

        // Add day-count context for velocity analysis
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cycleStart = calendar.startOfDay(for: currentCycle.startDate)
        let cycleEnd = calendar.startOfDay(for: currentCycle.endDate)
        let totalDays = (calendar.dateComponents([.day], from: cycleStart, to: cycleEnd).day ?? 30) + 1
        let daysElapsed = max(1, (calendar.dateComponents([.day], from: cycleStart, to: min(today, cycleEnd)).day ?? 0) + 1)

        lines.append("")
        lines.append("Cycle Duration: \(totalDays) days")
        lines.append("Days Elapsed: \(daysElapsed) of \(totalDays)")

        if totalExpenses > 0 {
            let dailyAvg = totalExpenses / Double(daysElapsed)
            lines.append("Daily Average Spend: \(dailyAvg.formattedRupiah)")
        }

        return lines.joined(separator: "\n")
    }
}
