import Foundation
import SwiftData

@Model
final class HeadCategory {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String

    @Relationship(deleteRule: .nullify, inverse: \Category.headCategory)
    var categories: [Category] = []

    init(name: String, icon: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
