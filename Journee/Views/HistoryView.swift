import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?

    var body: some View {
        Group {
            if let viewModel {
                HistoryContent(viewModel: viewModel)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HistoryViewModel(modelContext: modelContext)
            }
        }
    }
}

// MARK: - Content

struct HistoryContent: View {
    @Bindable var viewModel: HistoryViewModel
    @State private var expenseToEdit: Expense?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.allExpenses.isEmpty {
                    emptyState
                } else if viewModel.isSearching {
                    searchResultsList
                } else {
                    groupedList
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by note or category"
            )
            .sheet(item: $expenseToEdit) { expense in
                HistoryEditSheet(expense: expense) {
                    viewModel.loadData()
                }
                .presentationDetents([.large])
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.primary.opacity(0.12))

            Text("No transactions yet")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)

            Text("Your history will appear here")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.tertiary)

            Spacer()
        }
    }

    // MARK: - Grouped List (Default)

    private var groupedList: some View {
        List {
            ForEach(viewModel.groupedByMonth) { monthGroup in
                Section {
                    ForEach(monthGroup.dayGroups) { dayGroup in
                        // Day sub-header
                        Text(dayGroup.title)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)

                        // Expense rows for this day
                        ForEach(dayGroup.expenses, id: \.id) { expense in
                            Button {
                                expenseToEdit = expense
                            } label: {
                                HistoryRow(expense: expense)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { offsets in
                            for offset in offsets {
                                viewModel.deleteExpense(dayGroup.expenses[offset])
                            }
                        }
                    }
                } header: {
                    Text(monthGroup.title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Search Results (Flat)

    private var searchResultsList: some View {
        Group {
            if viewModel.filteredExpenses.isEmpty {
                VStack(spacing: 12) {
                    Spacer()

                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundStyle(.primary.opacity(0.12))

                    Text("No results for \"\(viewModel.searchText)\"")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.filteredExpenses, id: \.id) { expense in
                        Button {
                            expenseToEdit = expense
                        } label: {
                            HistoryRow(expense: expense, showDate: true)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let expense: Expense
    var showDate: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            if let category = expense.category {
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color(hex: category.colorHex))
                    )
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Color.gray.opacity(0.5))
                    )
            }

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.category?.name ?? "Uncategorized")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)

                if let note = expense.note, !note.isEmpty {
                    Text(note)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if showDate {
                    Text(formattedDate(expense.date))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Amount
            Text(formattedAmount(expense))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(expense.isIncome ? Color(hex: "22C55E") : .primary)
        }
        .padding(.vertical, 4)
    }

    private func formattedAmount(_ expense: Expense) -> String {
        let prefix = expense.isIncome ? "+" : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: expense.amount)) ?? "Rp0"
        return prefix + formatted
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - History Edit Sheet (wraps existing edit pattern)

struct HistoryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let expense: Expense
    var onSave: () -> Void

    @State private var amountText: String = ""
    @State private var note: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedCategory: Category?
    @State private var categories: [Category] = []
    @State private var isIncome: Bool = false

    private var isValid: Bool {
        guard let val = Double(amountText), val > 0 else { return false }
        return selectedCategory != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Type picker
                    Picker("Type", selection: $isIncome) {
                        Text("Expense").tag(false)
                        Text("Income").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isIncome) { _, newValue in
                        if newValue {
                            selectedCategory = categories.first(where: { $0.name == "Income" })
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

                    // Category
                    if !isIncome {
                        VStack(spacing: 8) {
                            Text("Category")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories.filter { $0.name != "Income" }, id: \.id) { category in
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
                    } else {
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
            .navigationTitle(isIncome ? "Edit Income" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .disabled(!isValid)
                }
            }
            .onAppear {
                amountText = String(format: "%.0f", expense.amount)
                note = expense.note ?? ""
                selectedDate = expense.date
                selectedCategory = expense.category
                isIncome = expense.isIncome
                loadCategories()
            }
        }
    }

    private func loadCategories() {
        let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
        categories = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func saveChanges() {
        guard let amount = Double(amountText) else { return }
        expense.amount = amount
        expense.date = selectedDate
        expense.note = note.isEmpty ? nil : note
        expense.category = selectedCategory
        expense.isIncome = isIncome
        try? modelContext.save()
        onSave()
        dismiss()
    }
}
