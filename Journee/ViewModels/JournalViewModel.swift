import Foundation
import Combine

class JournalViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var memo: String = ""
    @Published var selectedEmotion: Emotion?
    @Published var selectedCategory: Transaction.TransactionCategory?
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    private let repository: TransactionRepositoryProtocol
    
    init(repository: TransactionRepositoryProtocol = LocalTransactionRepository()) {
        self.repository = repository
    }
    
    func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            alertMessage = "Please enter a valid amount."
            showAlert = true
            return
        }
        
        guard !memo.isEmpty else {
            alertMessage = "Please enter a memo."
            showAlert = true
            return
        }
        
        guard let emotion = selectedEmotion else {
            alertMessage = "Please select an emotion."
            showAlert = true
            return
        }
        
        guard let category = selectedCategory else {
            alertMessage = "Please select a category."
            showAlert = true
            return
        }
        
        let transaction = Transaction(
            amount: amountValue,
            memo: memo,
            emotion: emotion,
            category: category,
            date: Date()
        )
        
        repository.save(transaction: transaction)
        
        // Reset fields
        amount = ""
        memo = ""
        selectedEmotion = nil
        selectedCategory = nil
        
        alertMessage = "Transaction saved successfully!"
        showAlert = true
    }
}
