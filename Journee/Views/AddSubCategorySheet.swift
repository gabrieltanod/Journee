import SwiftUI
import SwiftData

struct AddSubCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: DashboardViewModel
    let headCategory: HeadCategory

    @State private var name: String = ""
    @State private var selectedIcon: String = "tag.fill"

    private let iconOptions = [
        "tag.fill", "cup.and.saucer.fill", "book.fill", "gift.fill",
        "house.fill", "airplane", "tshirt.fill", "wrench.and.screwdriver.fill",
        "graduationcap.fill", "pawprint.fill", "music.note", "dumbbell.fill",
        "fork.knife", "cart.fill", "fuelpump.fill", "cross.case.fill",
        "film.fill", "paintbrush.fill",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Parent indicator
                HStack(spacing: 10) {
                    Image(systemName: headCategory.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: headCategory.colorHex))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color(hex: headCategory.colorHex).opacity(0.12))
                        )

                    Text("Under: \(headCategory.name)")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Color chip showing inherited color
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: headCategory.colorHex))
                            .frame(width: 10, height: 10)

                        Text("Color inherited")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                    )
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: headCategory.colorHex).opacity(0.06))
                )

                // Preview
                HStack(spacing: 12) {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: headCategory.colorHex))
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(hex: headCategory.colorHex).opacity(0.12))
                        )

                    Text(name.isEmpty ? "Sub-category" : name)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(name.isEmpty ? .secondary : .primary)

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                // Name
                TextField("Sub-category name", text: $name)
                    .font(.system(.body, design: .rounded))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                    )

                // Icon picker (no color picker — color is inherited)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(selectedIcon == icon
                                              ? Color(hex: headCategory.colorHex).opacity(0.15)
                                              : Color(.tertiarySystemFill))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(selectedIcon == icon
                                                      ? Color(hex: headCategory.colorHex).opacity(0.4)
                                                      : Color.clear, lineWidth: 1.5)
                                )
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("New Sub-Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        viewModel.addSubCategory(
                            name: name.trimmingCharacters(in: .whitespaces),
                            icon: selectedIcon,
                            under: headCategory
                        )
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
