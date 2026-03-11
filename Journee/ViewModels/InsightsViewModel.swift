import Foundation
import SwiftData
import SwiftUI

@Observable
final class InsightsViewModel {
    private var modelContext: ModelContext

    var selectedMonth: Date = Date()
    var categoryBreakdown: [CategorySlice] = []
    var selectedSlice: CategorySlice?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }

    // MARK: - Data

    func loadData() {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let startOfMonth = calendar.date(from: comps),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)
        else { return }

        let start = calendar.startOfDay(for: startOfMonth)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endOfMonth) ?? endOfMonth

        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= start && $0.date <= end }
        )
        let expenses = (try? modelContext.fetch(descriptor)) ?? []

        // Group by category
        var grouped: [String: (amount: Double, icon: String, colorHex: String)] = [:]

        for expense in expenses {
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

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Navigation

    func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
            loadData()
        }
    }

    func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
            loadData()
        }
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

