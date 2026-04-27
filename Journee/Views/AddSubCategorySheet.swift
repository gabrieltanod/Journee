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
            Form {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: headCategory.colorHex))
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: headCategory.colorHex).opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(name.isEmpty ? "New Sub-Category" : name)
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(name.isEmpty ? .secondary : .primary)

                            Text("Under: \(headCategory.name)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    TextField("Name", text: $name)
                        .font(.system(.body, design: .rounded))
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundStyle(selectedIcon == icon ? Color(hex: headCategory.colorHex) : .secondary)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedIcon == icon ? Color(hex: headCategory.colorHex).opacity(0.12) : Color.clear)
                                )
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
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
