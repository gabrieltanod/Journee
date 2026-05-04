import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var amount: Double
    var date: Date
    var note: String?
    var category: Category?
    var isIncome: Bool = false
    var wallet: Wallet?
    var isExcludedFromBudget: Bool = false

    init(amount: Double, date: Date, note: String? = nil, category: Category? = nil, isIncome: Bool = false, wallet: Wallet? = nil, isExcludedFromBudget: Bool = false) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.note = note
        self.category = category
        self.isIncome = isIncome
        self.wallet = wallet
        self.isExcludedFromBudget = isExcludedFromBudget
    }
}
