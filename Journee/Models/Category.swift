import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String

    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense] = []

    init(name: String, icon: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }

    static var defaults: [Category] {
        [
            Category(name: "Food", icon: "fork.knife", colorHex: "FF6B6B"),
            Category(name: "Transport", icon: "car.fill", colorHex: "4ECDC4"),
            Category(name: "Shopping", icon: "bag.fill", colorHex: "A78BFA"),
            Category(name: "Bills", icon: "bolt.fill", colorHex: "FBBF24"),
            Category(name: "Entertainment", icon: "gamecontroller.fill", colorHex: "F472B6"),
            Category(name: "Health", icon: "heart.fill", colorHex: "34D399"),
            Category(name: "Other", icon: "ellipsis.circle.fill", colorHex: "9CA3AF"),
        ]
    }
}
