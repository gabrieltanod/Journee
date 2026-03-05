import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var viewModel: DashboardViewModel

    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedDate: Date = Date()
    @State private var showNewCategory: Bool = false

    // New category form
    @State private var newCategoryName: String = ""
    @State private var newCategoryIcon: String = "tag.fill"
    @State private var newCategoryColor: String = "6366F1"

    private let iconOptions = [
        "tag.fill", "cup.and.saucer.fill", "book.fill", "gift.fill",
        "house.fill", "airplane", "tshirt.fill", "wrench.and.screwdriver.fill",
        "graduationcap.fill", "pawprint.fill", "music.note", "dumbbell.fill",
    ]

    private let colorOptions = [
        "FF6B6B", "4ECDC4", "A78BFA", "FBBF24",
        "F472B6", "34D399", "6366F1", "F97316",
        "06B6D4", "9CA3AF",
    ]

    private var isValid: Bool {
        guard let val = Double(amountText), val > 0 else { return false }
        return selectedCategory != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Amount
                    VStack(spacing: 8) {
                        Text("Amount")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("Rp")
                                .font(.system(.title3, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)

                            TextField("0", text: $amountText)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .keyboardType(.numberPad)
                        }

                        Rectangle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 1)
                    }

                    // Category picker
                    VStack(spacing: 12) {
                        HStack {
                            Text("Category")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showNewCategory.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: showNewCategory ? "xmark" : "plus")
                                        .font(.caption2)
                                    Text(showNewCategory ? "Cancel" : "New")
                                        .font(.system(.caption, design: .rounded, weight: .medium))
                                }
                                .foregroundStyle(.primary.opacity(0.6))
                            }
                        }

                        if showNewCategory {
                            newCategoryForm
                        }

                        // Category chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.categories, id: \.id) { category in
                                    CategoryChip(
                                        category: category,
                                        isSelected: selectedCategory?.id == category.id
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Note
                    VStack(spacing: 8) {
                        Text("Note")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("What's this for?", text: $note)
                            .font(.system(.body, design: .rounded))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(.tertiarySystemFill))
                            )
                    }

                    // Date
                    VStack(spacing: 8) {
                        Text("Date")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount = Double(amountText) else { return }
                        viewModel.saveExpense(
                            amount: amount,
                            date: selectedDate,
                            note: note.isEmpty ? nil : note,
                            category: selectedCategory
                        )
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - New Category Form

    private var newCategoryForm: some View {
        VStack(spacing: 12) {
            TextField("Category name", text: $newCategoryName)
                .font(.system(.body, design: .rounded))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                )

            // Icon picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(newCategoryIcon == icon
                                          ? Color.primary.opacity(0.1)
                                          : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(newCategoryIcon == icon
                                                  ? Color.primary.opacity(0.3)
                                                  : Color.clear, lineWidth: 1)
                            )
                            .onTapGesture { newCategoryIcon = icon }
                    }
                }
            }

            // Color picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(colorOptions, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.primary, lineWidth: newCategoryColor == hex ? 2 : 0)
                                    .padding(newCategoryColor == hex ? -2 : 0)
                            )
                            .onTapGesture { newCategoryColor = hex }
                    }
                }
            }

            Button {
                guard !newCategoryName.isEmpty else { return }
                viewModel.addCategory(
                    name: newCategoryName,
                    icon: newCategoryIcon,
                    colorHex: newCategoryColor
                )
                newCategoryName = ""
                withAnimation { showNewCategory = false }
            } label: {
                Text("Add Category")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(newCategoryName.isEmpty
                                  ? Color.primary.opacity(0.2)
                                  : Color.primary)
                    )
            }
            .disabled(newCategoryName.isEmpty)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Category Chip

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

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
