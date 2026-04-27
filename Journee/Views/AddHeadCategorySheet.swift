import SwiftUI
import SwiftData

struct AddHeadCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: DashboardViewModel

    @State private var name: String = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var selectedColor: String = "6366F1"

    private let iconOptions = [
        "folder.fill", "tray.full.fill", "archivebox.fill", "cart.fill",
        "house.fill", "car.fill", "heart.fill", "fork.knife",
        "airplane", "briefcase.fill", "book.fill", "gift.fill",
        "gamecontroller.fill", "graduationcap.fill", "wrench.and.screwdriver.fill",
        "leaf.fill", "star.fill", "flame.fill",
    ]

    private let colorOptions = [
        "FF6B6B", "4ECDC4", "A78BFA", "FBBF24",
        "F472B6", "34D399", "6366F1", "F97316",
        "06B6D4", "9CA3AF",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Preview
                HStack(spacing: 12) {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: selectedColor))
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: selectedColor).opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name.isEmpty ? "Head Category" : name)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(name.isEmpty ? .secondary : .primary)

                        Text("Parent group")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

                // Name
                TextField("Category name", text: $name)
                    .font(.system(.body, design: .rounded))
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                    )

                // Icon picker
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
                                              ? Color(hex: selectedColor).opacity(0.15)
                                              : Color(.tertiarySystemFill))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(selectedIcon == icon
                                                      ? Color(hex: selectedColor).opacity(0.4)
                                                      : Color.clear, lineWidth: 1.5)
                                )
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                }

                // Color picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary,
                                                      lineWidth: selectedColor == hex ? 2.5 : 0)
                                        .padding(selectedColor == hex ? -3 : 0)
                                )
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("New Head Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        viewModel.addHeadCategory(
                            name: name.trimmingCharacters(in: .whitespaces),
                            icon: selectedIcon,
                            colorHex: selectedColor
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
