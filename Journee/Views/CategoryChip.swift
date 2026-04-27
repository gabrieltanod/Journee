import SwiftUI
import SwiftData

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: category.colorHex))

            Text(category.name)
                .font(.system(.caption, design: .rounded, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(isSelected
                      ? Color(hex: category.colorHex).opacity(0.15)
                      : Color(.tertiarySystemFill))
        )
        .overlay(
            Capsule()
                .strokeBorder(isSelected
                              ? Color(hex: category.colorHex).opacity(0.4)
                              : Color.clear, lineWidth: 1)
        )
    }
}
