import Foundation
import SwiftData

@Model
final class Wallet {
    var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var initialBalance: Double
    var isDefault: Bool

    @Relationship(deleteRule: .nullify, inverse: \Expense.wallet)
    var expenses: [Expense] = []

    init(name: String, emoji: String, colorHex: String, initialBalance: Double = 0, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.initialBalance = initialBalance
        self.isDefault = isDefault
    }

    /// Calculated balance: initialBalance + incomes − expenses
    var calculatedBalance: Double {
        let incomes = expenses.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
        let spent = expenses.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
        return initialBalance + incomes - spent
    }
}
