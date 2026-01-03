import Foundation

protocol TransactionRepositoryProtocol {
    func fetchTransactions() -> [Transaction]
    func save(transaction: Transaction)
}

class LocalTransactionRepository: TransactionRepositoryProtocol {
    private let fileName = "transactions.json"
    
    // Get the URL for the documents directory
    private var documentsDirectory: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    // Get the URL for the transactions file
    private var fileURL: URL? {
        documentsDirectory?.appendingPathComponent(fileName)
    }
    
    func fetchTransactions() -> [Transaction] {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let transactions = try JSONDecoder().decode([Transaction].self, from: data)
            return transactions
        } catch {
            print("Error fetching transactions: \(error)")
            return []
        }
    }
    
    func save(transaction: Transaction) {
        var currentTransactions = fetchTransactions()
        currentTransactions.append(transaction)
        
        guard let url = fileURL else { return }
        
        do {
            let data = try JSONEncoder().encode(currentTransactions)
            try data.write(to: url)
        } catch {
            print("Error saving transaction: \(error)")
        }
    }
}
