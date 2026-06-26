import Foundation
import SwiftData

// MARK: - Transaction Type

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    case transfer

    var id: String { rawValue }

    var label: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .transfer: return "Transfer"
        }
    }
}

// MARK: - Transaction Model

@Model
final class Expense {
    var id: UUID
    var amount: Double
    var date: Date
    var note: String?
    var category: Category?
    var isIncome: Bool = false
    var isTransfer: Bool = false
    var wallet: Wallet?               // Source / "From" wallet
    var destinationWallet: Wallet?    // "To" wallet (transfers only)
    var isExcludedFromBudget: Bool = false

    /// Computed transaction type derived from stored booleans.
    var transactionType: TransactionType {
        if isTransfer { return .transfer }
        if isIncome { return .income }
        return .expense
    }

    init(
        amount: Double,
        date: Date,
        note: String? = nil,
        category: Category? = nil,
        transactionType: TransactionType = .expense,
        wallet: Wallet? = nil,
        destinationWallet: Wallet? = nil,
        isExcludedFromBudget: Bool = false
    ) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.note = note
        self.category = category
        self.isIncome = (transactionType == .income)
        self.isTransfer = (transactionType == .transfer)
        self.wallet = wallet
        self.destinationWallet = destinationWallet
        self.isExcludedFromBudget = isExcludedFromBudget
    }
}
