import Foundation

struct Transaction: Identifiable, Codable {
    var id: UUID = UUID()
    var amount: Double
    var memo: String
    var emotion: Emotion
    var category: TransactionCategory
    var date: Date
    
    enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
        case needs = "Needs"
        case wants = "Wants"
        
        var id: String { rawValue }
    }
}
