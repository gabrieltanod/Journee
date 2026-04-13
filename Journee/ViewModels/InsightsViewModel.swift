import Foundation
import SwiftData
import SwiftUI

@Observable
final class InsightsViewModel {
    private var modelContext: ModelContext
    private var payday: Int

    var currentCycle: PaydayCycle
    var categoryBreakdown: [CategorySlice] = []
    var selectedSlice: CategorySlice?
    var totalIncome: Double = 0

    init(modelContext: ModelContext, payday: Int = 1) {
        self.modelContext = modelContext
        self.payday = payday
        self.currentCycle = PaydayCycle.cycle(containing: Date(), payday: payday)
        loadData()
    }

    // MARK: - Payday Update

    func updatePayday(_ newPayday: Int) {
        payday = newPayday
        currentCycle = PaydayCycle.cycle(containing: currentCycle.startDate, payday: newPayday)
        loadData()
    }

    // MARK: - Data

    func loadData() {
        let start = currentCycle.fetchStartDate
        let end = currentCycle.fetchEndDate

        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= start && $0.date <= end }
        )
        let allItems = (try? modelContext.fetch(descriptor)) ?? []

        // Separate income and expenses
        let expenseItems = allItems.filter { !$0.isIncome }
        let incomeItems = allItems.filter { $0.isIncome }

        totalIncome = incomeItems.reduce(0) { $0 + $1.amount }

        // Group expenses by category (income excluded from chart)
        var grouped: [String: (amount: Double, icon: String, colorHex: String)] = [:]

        for expense in expenseItems {
            let name = expense.category?.name ?? "Uncategorized"
            let icon = expense.category?.icon ?? "questionmark.circle.fill"
            let colorHex = expense.category?.colorHex ?? "9CA3AF"

            if var entry = grouped[name] {
                entry.amount += expense.amount
                grouped[name] = entry
            } else {
                grouped[name] = (amount: expense.amount, icon: icon, colorHex: colorHex)
            }
        }

        categoryBreakdown = grouped.map { name, info in
            CategorySlice(
                name: name,
                amount: info.amount,
                icon: info.icon,
                colorHex: info.colorHex
            )
        }
        .sorted { $0.amount > $1.amount }

        // Reset selection if it no longer exists
        if let selected = selectedSlice,
           !categoryBreakdown.contains(where: { $0.name == selected.name }) {
            selectedSlice = nil
        }
    }

    // MARK: - Computed

    var totalSpent: Double {
        categoryBreakdown.reduce(0) { $0 + $1.amount }
    }

    var cycleLabel: String {
        currentCycle.label
    }

    var isCurrentCycle: Bool {
        currentCycle.isCurrentCycle
    }

    // MARK: - Navigation

    func nextCycle() {
        currentCycle = currentCycle.next(payday: payday)
        loadData()
    }

    func previousCycle() {
        currentCycle = currentCycle.previous(payday: payday)
        loadData()
    }
}

// MARK: - Slice Model

struct CategorySlice: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let amount: Double
    let icon: String
    let colorHex: String

    var color: Color {
        Color(hex: colorHex)
    }

    static func == (lhs: CategorySlice, rhs: CategorySlice) -> Bool {
        lhs.name == rhs.name && lhs.amount == rhs.amount
    }
}
