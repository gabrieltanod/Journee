import Foundation
import SwiftData

@Model
final class MonthlyBudget {
    var id: UUID
    var month: Int
    var year: Int
    var amount: Double

    init(month: Int, year: Int, amount: Double) {
        self.id = UUID()
        self.month = month
        self.year = year
        self.amount = amount
    }
}
