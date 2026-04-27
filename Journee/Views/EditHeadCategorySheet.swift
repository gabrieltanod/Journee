import SwiftUI
import SwiftData

struct EditHeadCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: DashboardViewModel
    let headCategory: HeadCategory

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
            Form {
                Section {
                    TextField("Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : .secondary)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.12) : Color.clear)
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(selectedColor == hex ? 0.3 : 0), lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = hex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Head Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        viewModel.updateHeadCategory(headCategory, name: trimmed, icon: selectedIcon, colorHex: selectedColor)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = headCategory.name
                selectedIcon = headCategory.icon
                selectedColor = headCategory.colorHex
            }
        }
    }
}
