import SwiftUI
import SwiftData

struct EditCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: DashboardViewModel
    let category: Category

    @State private var name: String = ""
    @State private var selectedIcon: String = "tag.fill"
    @State private var selectedHead: HeadCategory? = nil

    private let iconOptions = [
        "tag.fill", "cup.and.saucer.fill", "book.fill", "gift.fill",
        "house.fill", "airplane", "tshirt.fill", "wrench.and.screwdriver.fill",
        "graduationcap.fill", "pawprint.fill", "music.note", "dumbbell.fill",
        "fork.knife", "cart.fill", "fuelpump.fill", "cross.case.fill",
        "film.fill", "paintbrush.fill", "ellipsis.circle.fill", "banknote.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }

                Section("Head Category") {
                    Picker("Head Category", selection: $selectedHead) {
                        Text("None").tag(HeadCategory?(nil))
                        ForEach(viewModel.headCategories, id: \.id) { head in
                            Text(head.name).tag(HeadCategory?(head))
                        }
                    }
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            let colorHex = selectedHead?.colorHex ?? category.colorHex
                            Image(systemName: icon)
                                .font(.system(size: 20))
                                .foregroundStyle(selectedIcon == icon ? Color(hex: colorHex) : .secondary)
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selectedIcon == icon ? Color(hex: colorHex).opacity(0.12) : Color.clear)
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        viewModel.updateCategory(category, name: trimmed, icon: selectedIcon, headCategory: selectedHead)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = category.name
                selectedIcon = category.icon
                selectedHead = category.headCategory
            }
        }
    }
}
