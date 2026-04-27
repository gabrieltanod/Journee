import Foundation
import SwiftData
import SwiftUI

// MARK: - Grouping Mode

enum InsightsGrouping: String, CaseIterable, Identifiable {
    case headCategories = "Head Categories"
    case allCategories = "All Categories"

    var id: String { rawValue }
}

@Observable
final class InsightsViewModel {
    private var modelContext: ModelContext
    private var payday: Int

    var currentCycle: PaydayCycle
    var groupingMode: InsightsGrouping = .headCategories

    // State B — flat category breakdown (original)
    var categoryBreakdown: [CategorySlice] = []
    var selectedSlice: CategorySlice?

    // State A — head-category grouped breakdown
    var headCategoryBreakdown: [HeadCategorySlice] = []
    var selectedHeadSlice: HeadCategorySlice?

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

        buildFlatBreakdown(from: expenseItems)
        buildHeadCategoryBreakdown(from: expenseItems)
    }

    // MARK: - State B: Flat grouping (original logic)

    private func buildFlatBreakdown(from expenses: [Expense]) {
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

    // MARK: - State A: Head-category grouping

    private func buildHeadCategoryBreakdown(from expenses: [Expense]) {
        // key: headCategory name (or category name if standalone)
        struct GroupKey: Hashable { let name: String }
        struct GroupInfo {
            var totalAmount: Double
            var icon: String
            var colorHex: String
            var children: [String: (amount: Double, icon: String, colorHex: String)]
        }

        var groups: [GroupKey: GroupInfo] = [:]

        for expense in expenses {
            let category = expense.category
            let catName = category?.name ?? "Uncategorized"
            let catIcon = category?.icon ?? "questionmark.circle.fill"
            let catColorHex = category?.colorHex ?? "9CA3AF"

            if let head = category?.headCategory {
                // This category belongs to a head category
                let key = GroupKey(name: head.name)

                if var group = groups[key] {
                    group.totalAmount += expense.amount
                    if var child = group.children[catName] {
                        child.amount += expense.amount
                        group.children[catName] = child
                    } else {
                        group.children[catName] = (amount: expense.amount, icon: catIcon, colorHex: catColorHex)
                    }
                    groups[key] = group
                } else {
                    groups[key] = GroupInfo(
                        totalAmount: expense.amount,
                        icon: head.icon,
                        colorHex: head.colorHex,
                        children: [catName: (amount: expense.amount, icon: catIcon, colorHex: catColorHex)]
                    )
                }
            } else {
                // Standalone category — acts as its own group
                let key = GroupKey(name: catName)

                if var group = groups[key] {
                    group.totalAmount += expense.amount
                    // Standalone categories have no children; track as a single child for consistency
                    if var child = group.children[catName] {
                        child.amount += expense.amount
                        group.children[catName] = child
                    }
                    groups[key] = group
                } else {
                    groups[key] = GroupInfo(
                        totalAmount: expense.amount,
                        icon: catIcon,
                        colorHex: catColorHex,
                        children: [catName: (amount: expense.amount, icon: catIcon, colorHex: catColorHex)]
                    )
                }
            }
        }

        headCategoryBreakdown = groups.map { key, info in
            let childSlices = info.children.map { childName, childInfo in
                CategorySlice(
                    name: childName,
                    amount: childInfo.amount,
                    icon: childInfo.icon,
                    colorHex: childInfo.colorHex
                )
            }.sorted { $0.amount > $1.amount }

            let isStandalone = info.children.count == 1 && info.children.keys.first == key.name

            return HeadCategorySlice(
                name: key.name,
                totalAmount: info.totalAmount,
                icon: info.icon,
                colorHex: info.colorHex,
                children: childSlices,
                isStandalone: isStandalone
            )
        }.sorted { $0.totalAmount > $1.totalAmount }

        // Reset selection if it no longer exists
        if let selected = selectedHeadSlice,
           !headCategoryBreakdown.contains(where: { $0.name == selected.name }) {
            selectedHeadSlice = nil
        }
    }

    // MARK: - Active breakdown for chart (whichever mode is selected)

    var activeChartSlices: [CategorySlice] {
        switch groupingMode {
        case .allCategories:
            return categoryBreakdown
        case .headCategories:
            return headCategoryBreakdown.map { head in
                CategorySlice(
                    name: head.name,
                    amount: head.totalAmount,
                    icon: head.icon,
                    colorHex: head.colorHex
                )
            }
        }
    }

    var activeSelectedSlice: CategorySlice? {
        switch groupingMode {
        case .allCategories:
            return selectedSlice
        case .headCategories:
            if let sel = selectedHeadSlice {
                return CategorySlice(
                    name: sel.name,
                    amount: sel.totalAmount,
                    icon: sel.icon,
                    colorHex: sel.colorHex
                )
            }
            return nil
        }
    }

    func selectActiveSlice(_ slice: CategorySlice?) {
        switch groupingMode {
        case .allCategories:
            selectedSlice = slice
        case .headCategories:
            if let slice {
                selectedHeadSlice = headCategoryBreakdown.first(where: { $0.name == slice.name })
            } else {
                selectedHeadSlice = nil
            }
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

// MARK: - Head Category Slice Model

struct HeadCategorySlice: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let totalAmount: Double
    let icon: String
    let colorHex: String
    let children: [CategorySlice]
    let isStandalone: Bool  // true when this is just a standalone category with no real head

    var color: Color {
        Color(hex: colorHex)
    }

    static func == (lhs: HeadCategorySlice, rhs: HeadCategorySlice) -> Bool {
        lhs.name == rhs.name && lhs.totalAmount == rhs.totalAmount
    }
}
