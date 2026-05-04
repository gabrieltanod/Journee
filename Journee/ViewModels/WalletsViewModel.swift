import Foundation
import SwiftData
import SwiftUI

@Observable
final class WalletsViewModel {
    private var modelContext: ModelContext

    var wallets: [Wallet] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadWallets()
    }

    // MARK: - Data Loading

    func loadWallets() {
        let descriptor = FetchDescriptor<Wallet>(sortBy: [SortDescriptor(\.name)])
        wallets = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - CRUD

    func addWallet(name: String, emoji: String, colorHex: String, initialBalance: Double) {
        let wallet = Wallet(
            name: name,
            emoji: emoji,
            colorHex: colorHex,
            initialBalance: initialBalance
        )
        modelContext.insert(wallet)
        try? modelContext.save()
        loadWallets()
    }

    func updateWallet(_ wallet: Wallet, name: String, emoji: String, colorHex: String, initialBalance: Double) {
        wallet.name = name
        wallet.emoji = emoji
        wallet.colorHex = colorHex
        wallet.initialBalance = initialBalance
        try? modelContext.save()
        loadWallets()
    }

    /// Delete a wallet.
    /// - Parameters:
    ///   - wallet: The wallet to delete.
    ///   - keepTransactions: If true, transactions are kept but unlinked (nullified). If false, all associated transactions are deleted.
    func deleteWallet(_ wallet: Wallet, keepTransactions: Bool) {
        if keepTransactions {
            // Nullify — SwiftData's .nullify delete rule handles this,
            // but let's be explicit to ensure consistency
            for expense in wallet.expenses {
                expense.wallet = nil
            }
        } else {
            // Delete all associated transactions
            for expense in wallet.expenses {
                modelContext.delete(expense)
            }
        }
        modelContext.delete(wallet)
        try? modelContext.save()
        loadWallets()
    }

    /// Returns the default "Cash" wallet
    func defaultWallet() -> Wallet? {
        wallets.first(where: { $0.isDefault })
    }

    /// Transactions for a specific wallet, sorted by date descending
    func expenses(for wallet: Wallet) -> [Expense] {
        wallet.expenses.sorted { $0.date > $1.date }
    }
}
