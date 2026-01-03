import Foundation
import Combine

class HistoryViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var selectedDate: Date = Date()
    
    private let repository: TransactionRepositoryProtocol
    
    init(repository: TransactionRepositoryProtocol = LocalTransactionRepository()) {
        self.repository = repository
        loadTransactions()
    }
    
    func loadTransactions() {
        self.transactions = repository.fetchTransactions().sorted(by: { $0.date > $1.date })
    }
    
    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedDate, toGranularity: .month)
        }
    }
    
    var totalAmount: Double {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }
    
    var categoryBreakdown: [Transaction.TransactionCategory: Double] {
        Dictionary(grouping: filteredTransactions, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }
    
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
}
