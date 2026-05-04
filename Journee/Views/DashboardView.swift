import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("payday") private var payday: Int = 1
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        Group {
            if let viewModel {
                DashboardContent(viewModel: viewModel)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = DashboardViewModel(modelContext: modelContext, payday: payday)
            }
        }
        .onChange(of: payday) { _, newValue in
            viewModel?.updatePayday(newValue)
        }
    }
}

// MARK: - Dashboard Content (non-optional viewModel)

struct DashboardContent: View {
    @Bindable var viewModel: DashboardViewModel

    @State private var selectedDate: Date?
    @State private var showAddExpense: Bool = false
    @State private var appState = AppState.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 24) {
                        budgetCard
                        calendarSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                }
                .background(Color(.systemBackground))

                // Floating Action Button
                Button {
                    showAddExpense = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color(hex: "1C1C1E"))
                                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 16)
            }
            .navigationTitle("Journee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.6))
                    }
                }
            }
            .navigationDestination(item: $selectedDate) { date in
                DailyDetailView(
                    viewModel: viewModel,
                    date: date
                )
            }
        }
        .sheet(isPresented: $viewModel.showBudgetPrompt) {
            BudgetPromptView(
                onSave: { amount in
                    viewModel.saveBudget(amount: amount)
                },
                onSkip: {
                    viewModel.showBudgetPrompt = false
                }
            )
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseSheet(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .onChange(of: appState.shouldShowQuickAdd) { _, shouldShow in
            if shouldShow {
                showAddExpense = true
                appState.shouldShowQuickAdd = false
            }
        }
    }

    // MARK: - Budget Card

    private var budgetCard: some View {
        VStack(spacing: 16) {
            if viewModel.hasBudget {
                // Budget is set — show remaining + progress
                VStack(spacing: 4) {
                    Text("Remaining")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(formattedCurrency(viewModel.remainingBudget))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.isOverBudget ? .red : .primary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(.tertiarySystemFill))

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(progressColor(viewModel.spentPercentage))
                            .frame(width: geo.size.width * viewModel.spentPercentage)
                            .animation(.easeInOut(duration: 0.4), value: viewModel.spentPercentage)
                    }
                }
                .frame(height: 6)

                HStack {
                    Label(formattedCurrency(viewModel.totalSpentForBudget), systemImage: "arrow.up.right")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Label(formattedCurrency(viewModel.budgetAmount), systemImage: "target")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                // Summary row: Income & Spent
                summaryRow

                // Edit budget button
                Button {
                    viewModel.showBudgetPrompt = true
                } label: {
                    Label("Edit Budget", systemImage: "pencil")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } else {
                // No budget set — show spent only + option to set budget
                VStack(spacing: 4) {
                    Text("Spent This Month")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text(formattedCurrency(viewModel.totalSpentForBudget))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                // Summary row: Income & Spent
                summaryRow

                Button {
                    viewModel.showBudgetPrompt = true
                } label: {
                    Label("Set Budget", systemImage: "plus.circle")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.6))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Summary Row

    private var summaryRow: some View {
        HStack(spacing: 0) {
            // Total Income
            HStack(spacing: 6) {
                Image(systemName: "arrow.down.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "22C55E"))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Income")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text(formattedCurrency(viewModel.totalIncome))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color(hex: "22C55E"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 1, height: 28)

            // Total Spent
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Spent")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text(formattedCurrency(viewModel.totalSpent))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        )
    }

    private func progressColor(_ pct: Double) -> Color {
        if pct >= 0.9 { return .red }
        if pct >= 0.7 { return .orange }
        return Color.secondary
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(spacing: 16) {
            // Cycle nav
            HStack {
                Button { viewModel.previousCycle() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.5))
                }

                Spacer()

                Text(viewModel.cycleLabel)
                    .font(.system(.body, design: .rounded, weight: .semibold))

                if viewModel.isCurrentCycle {
                    Text("NOW")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.black))
                }

                Spacer()

                Button { viewModel.nextCycle() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.5))
                }
            }

            CalendarGridView(
                cycle: viewModel.currentCycle,
                dailyTotals: viewModel.dailyTotals,
                onDayTapped: { date in
                    selectedDate = date
                }
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Helpers

    private func formattedCurrency(_ value: Double) -> String {
        return value.formattedRupiah
    }
}
