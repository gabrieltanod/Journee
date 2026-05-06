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
            // Nullify source wallet link
            for expense in wallet.expenses {
                expense.wallet = nil
            }
            // Nullify destination wallet link for incoming transfers
            for transfer in wallet.incomingTransfers {
                transfer.destinationWallet = nil
            }
        } else {
            // Delete all associated transactions (outgoing)
            for expense in wallet.expenses {
                modelContext.delete(expense)
            }
            // Delete incoming transfers too
            for transfer in wallet.incomingTransfers {
                modelContext.delete(transfer)
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

    /// All transactions involving this wallet (outgoing + incoming transfers), sorted by date descending
    func expenses(for wallet: Wallet) -> [Expense] {
        var seen = Set<UUID>()
        var combined: [Expense] = []
        for expense in wallet.expenses {
            if seen.insert(expense.id).inserted {
                combined.append(expense)
            }
        }
        for transfer in wallet.incomingTransfers {
            if seen.insert(transfer.id).inserted {
                combined.append(transfer)
            }
        }
        return combined.sorted { $0.date > $1.date }
    }
}
