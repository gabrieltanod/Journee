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
    @State private var selectedType: TransactionType = .expense
    @State private var showCategorySheet: Bool = false
    @State private var selectedWallet: Wallet?
    @State private var selectedDestinationWallet: Wallet?
    @State private var isExcludedFromBudget: Bool = false

    private var isEditing: Bool { existingExpense != nil }

    private var isValid: Bool {
        guard let val = Double(amountText), val > 0 else { return false }
        switch selectedType {
        case .expense:
            return selectedCategory != nil
        case .income:
            return true
        case .transfer:
            return selectedWallet != nil && selectedDestinationWallet != nil
        }
    }

    /// Wallets available for the "To" picker — excludes the currently selected "From" wallet
    private var destinationWallets: [Wallet] {
        viewModel.wallets.filter { $0.id != selectedWallet?.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Type picker (Expense / Income / Transfer)
                    Picker("Type", selection: $selectedType) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedType) { _, newValue in
                        switch newValue {
                        case .income:
                            selectedCategory = viewModel.incomeCategory()
                            isExcludedFromBudget = false
                            selectedDestinationWallet = nil
                        case .expense:
                            if selectedCategory?.name == "Income" {
                                selectedCategory = nil
                            }
                            selectedDestinationWallet = nil
                        case .transfer:
                            selectedCategory = nil
                            isExcludedFromBudget = true
                            // Auto-pick first available destination
                            if selectedDestinationWallet == nil {
                                selectedDestinationWallet = destinationWallets.first
                            }
                        }
                    }

                    // Amount
                    amountSection

                    // Category row — hidden for transfers
                    if selectedType == .expense {
                        categoryRow
                    } else if selectedType == .income {
                        incomeIndicator
                    }

                    // Note
                    noteSection

                    // Date
                    dateSection

                    // Wallet (From)
                    walletFromSection

                    // Wallet (To) — only for transfers
                    if selectedType == .transfer {
                        walletToSection
                    }

                    // Exclude from budget toggle — only for expenses
                    if selectedType == .expense {
                        budgetExcludeToggle
                    }
                }
                .padding(20)
            }
            .navigationTitle(navigationTitle)
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

    // MARK: - Navigation Title

    private var navigationTitle: String {
        switch selectedType {
        case .expense:
            return isEditing ? "Edit Expense" : "Add Expense"
        case .income:
            return isEditing ? "Edit Income" : "Add Income"
        case .transfer:
            return isEditing ? "Edit Transfer" : "New Transfer"
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
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
    }

    // MARK: - Category Row

    private var categoryRow: some View {
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
    }

    // MARK: - Income Indicator

    private var incomeIndicator: some View {
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

    // MARK: - Note Section

    private var noteSection: some View {
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
    }

    // MARK: - Date Section

    private var dateSection: some View {
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

    // MARK: - Wallet From Section

    private var walletFromSection: some View {
        VStack(spacing: 8) {
            Text("From")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                ForEach(viewModel.wallets, id: \.id) { wallet in
                    Button {
                        selectedWallet = wallet
                        // If the destination matches the new source, clear it
                        if selectedDestinationWallet?.id == wallet.id {
                            selectedDestinationWallet = destinationWallets.first
                        }
                    } label: {
                        Label {
                            Text(wallet.name)
                        } icon: {
                            Text(wallet.emoji)
                        }
                    }
                }
            } label: {
                walletPickerLabel(wallet: selectedWallet, placeholder: "Select a wallet")
            }
        }
    }

    // MARK: - Wallet To Section (Transfer only)

    private var walletToSection: some View {
        VStack(spacing: 8) {
            Text("To")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                ForEach(destinationWallets, id: \.id) { wallet in
                    Button {
                        selectedDestinationWallet = wallet
                    } label: {
                        Label {
                            Text(wallet.name)
                        } icon: {
                            Text(wallet.emoji)
                        }
                    }
                }
            } label: {
                walletPickerLabel(wallet: selectedDestinationWallet, placeholder: "Select destination")
            }
        }
    }

    // MARK: - Reusable Wallet Picker Label

    private func walletPickerLabel(wallet: Wallet?, placeholder: String) -> some View {
        HStack(spacing: 10) {
            if let wallet {
                Text(wallet.emoji)
                    .font(.system(size: 18))
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(hex: wallet.colorHex).opacity(0.15))
                    )

                Text(wallet.name)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)
            } else {
                Image(systemName: "wallet.bifold")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)

                Text(placeholder)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary.opacity(0.25))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }

    // MARK: - Budget Exclude Toggle

    private var budgetExcludeToggle: some View {
        VStack(spacing: 6) {
            Toggle(isOn: $isExcludedFromBudget) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isExcludedFromBudget ? .orange : .secondary)

                    Text("Exclude from budget")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                }
            }
            .tint(.orange)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isExcludedFromBudget ? Color.orange.opacity(0.08) : Color(.tertiarySystemFill))
            )
            .animation(.easeInOut(duration: 0.2), value: isExcludedFromBudget)

            if isExcludedFromBudget {
                Text("This transaction will only affect the wallet balance, not your monthly budget.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
            selectedType = expense.transactionType
            selectedWallet = expense.wallet
            selectedDestinationWallet = expense.destinationWallet
            isExcludedFromBudget = expense.isExcludedFromBudget
        } else {
            // Default to Cash wallet for new entries
            selectedWallet = viewModel.defaultWallet()
            if let date = prefilledDate {
                selectedDate = date
            }
        }
    }

    // MARK: - Save

    private func saveExpense() {
        guard let amount = Double(amountText) else { return }

        // Transfers are always excluded from budget
        let excludeFromBudget: Bool
        switch selectedType {
        case .transfer:
            excludeFromBudget = true
        case .income:
            excludeFromBudget = false
        case .expense:
            excludeFromBudget = isExcludedFromBudget
        }

        if let expense = existingExpense {
            viewModel.updateExpense(
                expense,
                amount: amount,
                date: selectedDate,
                note: note.isEmpty ? nil : note,
                category: selectedType == .transfer ? nil : selectedCategory,
                transactionType: selectedType,
                wallet: selectedWallet,
                destinationWallet: selectedType == .transfer ? selectedDestinationWallet : nil,
                isExcludedFromBudget: excludeFromBudget
            )
        } else {
            viewModel.saveExpense(
                amount: amount,
                date: selectedDate,
                note: note.isEmpty ? nil : note,
                category: selectedType == .transfer ? nil : selectedCategory,
                transactionType: selectedType,
                wallet: selectedWallet,
                destinationWallet: selectedType == .transfer ? selectedDestinationWallet : nil,
                isExcludedFromBudget: excludeFromBudget
            )
        }
        dismiss()
    }
}
