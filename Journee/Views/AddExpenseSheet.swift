import SwiftUI
import SwiftData

struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var viewModel: DashboardViewModel
    var existingExpense: Expense? = nil
    var prefilledDate: Date? = nil

    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedDate: Date = Date()
    @State private var isIncome: Bool = false
    @State private var showCategorySheet: Bool = false

    private var isEditing: Bool { existingExpense != nil }

    private var isValid: Bool {
        guard let val = Double(amountText), val > 0 else { return false }
        return selectedCategory != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Type picker (Income / Expense)
                    Picker("Type", selection: $isIncome) {
                        Text("Expense").tag(false)
                        Text("Income").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isIncome) { _, newValue in
                        if newValue {
                            selectedCategory = viewModel.incomeCategory()
                        } else {
                            if selectedCategory?.name == "Income" {
                                selectedCategory = nil
                            }
                        }
                    }

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

                    // Category row (tappable → opens sheet)
                    if !isIncome {
                        VStack(spacing: 8) {
                            Text("Category")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                showCategorySheet = true
                            } label: {
                                HStack(spacing: 10) {
                                    if let cat = selectedCategory {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 14))
                                            .foregroundStyle(Color(hex: cat.colorHex))
                                            .frame(width: 28, height: 28)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .fill(Color(hex: cat.colorHex).opacity(0.12))
                                            )

                                        Text(cat.name)
                                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                                            .foregroundStyle(.primary)
                                    } else {
                                        Image(systemName: "square.grid.2x2")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 28, height: 28)

                                        Text("Select a category")
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.primary.opacity(0.25))
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color(.tertiarySystemFill))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        // Show income category indicator
                        HStack(spacing: 8) {
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "22C55E"))

                            Text("Income")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: "22C55E"))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(hex: "22C55E").opacity(0.1))
                        )
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
            .navigationTitle(isEditing
                             ? (isIncome ? "Edit Income" : "Edit Expense")
                             : (isIncome ? "Add Income" : "Add Expense"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .disabled(!isValid)
                }
            }
            .onAppear {
                prefillFields()
            }
            .sheet(isPresented: $showCategorySheet) {
                CategorySelectionSheet(
                    viewModel: viewModel,
                    selectedCategory: $selectedCategory
                )
                .presentationDetents([.large])
            }
        }
    }

    // MARK: - Prefill

    private func prefillFields() {
        if let expense = existingExpense {
            amountText = String(format: "%.0f", expense.amount)
            note = expense.note ?? ""
            selectedCategory = expense.category
            selectedDate = expense.date
            isIncome = expense.isIncome
        } else if let date = prefilledDate {
            selectedDate = date
        }
    }

    // MARK: - Save

    private func saveExpense() {
        guard let amount = Double(amountText) else { return }

        if let expense = existingExpense {
            viewModel.updateExpense(
                expense,
                amount: amount,
                date: selectedDate,
                note: note.isEmpty ? nil : note,
                category: selectedCategory,
                isIncome: isIncome
            )
        } else {
            viewModel.saveExpense(
                amount: amount,
                date: selectedDate,
                note: note.isEmpty ? nil : note,
                category: selectedCategory,
                isIncome: isIncome
            )
        }
        dismiss()
    }
}

// MARK: - Category Selection Sheet

struct CategorySelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: DashboardViewModel
    @Binding var selectedCategory: Category?

    @State private var expandedHeadCategories: Set<UUID> = []
    @State private var showAddHeadCategory: Bool = false
    @State private var targetHeadCategory: HeadCategory? = nil

    var body: some View {
        NavigationStack {
            List {
                // 1. Most Frequent categories
                let frequent = mostFrequentCategories(limit: 3)
                if !frequent.isEmpty {
                    Section {
                        ForEach(frequent, id: \.id) { category in
                            categoryButton(for: category)
                        }
                    } header: {
                        Text("Most Frequent")
                    }
                }

                // 2. Head categories with sub-categories
                ForEach(viewModel.headCategories, id: \.id) { head in
                    Section {
                        let children = viewModel.categories.filter { $0.headCategory?.id == head.id }

                        // Head category label row
                        DisclosureGroup(
                            isExpanded: expandedBinding(for: head.id)
                        ) {
                            ForEach(children, id: \.id) { category in
                                subCategoryButton(for: category)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            if selectedCategory?.id == category.id {
                                                selectedCategory = nil
                                            }
                                            viewModel.deleteCategory(category)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }

                            // Add sub-category button
                            Button {
                                targetHeadCategory = head
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(hex: head.colorHex).opacity(0.6))

                                    Text("Add sub-category")
                                        .font(.system(.caption, design: .rounded, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: head.icon)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: head.colorHex))
                                    .frame(width: 30, height: 30)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(Color(hex: head.colorHex).opacity(0.12))
                                    )

                                Text(head.name)
                                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                    .foregroundStyle(.primary)

                                Spacer()

                                let count = viewModel.categories.filter { $0.headCategory?.id == head.id }.count
                                Text("\(count)")
                                    .font(.system(.caption2, design: .rounded, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color(.tertiarySystemFill))
                                    )
                            }
                        }
                        .tint(.secondary)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                // Clear selection if a child was selected
                                let childIds = viewModel.categories
                                    .filter { $0.headCategory?.id == head.id }
                                    .map { $0.id }
                                if let sel = selectedCategory, childIds.contains(sel.id) {
                                    selectedCategory = nil
                                }
                                viewModel.deleteHeadCategory(head)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } header: {
                        if head.id == viewModel.headCategories.first?.id {
                            Text("Head Categories")
                        }
                    }
                }

                // 3. Standalone categories (no head category, excluding Income)
                let standalone = viewModel.categories.filter {
                    $0.headCategory == nil && $0.name != "Income"
                }

                if !standalone.isEmpty {
                    Section {
                        ForEach(standalone, id: \.id) { category in
                            categoryButton(for: category)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        if selectedCategory?.id == category.id {
                                            selectedCategory = nil
                                        }
                                        viewModel.deleteCategory(category)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        Text("Other Categories")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showAddHeadCategory = true
                        } label: {
                            Label("New Head Category", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(isPresented: $showAddHeadCategory) {
                AddHeadCategorySheet(viewModel: viewModel)
                    .presentationDetents([.large])
            }
            .sheet(item: $targetHeadCategory) { head in
                AddSubCategorySheet(viewModel: viewModel, headCategory: head)
                    .presentationDetents([.large])
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    // MARK: - Most Frequent

    private func mostFrequentCategories(limit: Int) -> [Category] {
        let nonIncome = viewModel.categories.filter {
            $0.name != "Income" && !$0.expenses.isEmpty
        }
        return Array(
            nonIncome
                .sorted { $0.expenses.count > $1.expenses.count }
                .prefix(limit)
        )
    }

    // MARK: - Category Row (standalone / most frequent)

    private func categoryButton(for category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: category.colorHex))
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color(hex: category.colorHex).opacity(0.12))
                    )

                Text(category.name)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: category.colorHex))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sub-Category Row

    private func subCategoryButton(for category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: category.colorHex))
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(hex: category.colorHex).opacity(0.1))
                    )

                Text(category.name)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: category.colorHex))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func expandedBinding(for headId: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedHeadCategories.contains(headId) },
            set: { isExpanded in
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedHeadCategories.insert(headId)
                    } else {
                        expandedHeadCategories.remove(headId)
                    }
                }
            }
        )
    }
}

// MARK: - Add Head Category Sheet

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

// MARK: - Add Sub-Category Sheet

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
