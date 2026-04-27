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

