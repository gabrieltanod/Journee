import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
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
                viewModel = DashboardViewModel(modelContext: modelContext)
            }
        }
    }
}

// MARK: - Dashboard Content (non-optional viewModel)

struct DashboardContent: View {
    @Bindable var viewModel: DashboardViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    budgetCard
                    calendarSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        viewModel.showAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.primary)
                                    .shadow(color: .primary.opacity(0.25), radius: 12, y: 6)
                            )
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showBudgetPrompt) {
            BudgetPromptView { amount in
                viewModel.saveBudget(amount: amount)
            }
        }
        .sheet(isPresented: $viewModel.showAddExpense) {
            AddExpenseSheet(viewModel: viewModel)
                .presentationDetents([.large])
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Journee")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                Text(currentDateString())
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.primary.opacity(0.15))
        }
        .padding(.top, 12)
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Budget Card

    private var budgetCard: some View {
        VStack(spacing: 16) {
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
                Label(formattedCurrency(viewModel.totalSpent), systemImage: "arrow.up.right")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Label(formattedCurrency(viewModel.budgetAmount), systemImage: "target")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func progressColor(_ pct: Double) -> Color {
        if pct >= 0.9 { return .red }
        if pct >= 0.7 { return .orange }
        return Color.primary.opacity(0.6)
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(spacing: 16) {
            // Month nav
            HStack {
                Button { viewModel.previousMonth() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.5))
                }

                Spacer()

                Text(viewModel.monthYearString)
                    .font(.system(.body, design: .rounded, weight: .semibold))

                if viewModel.isCurrentMonth {
                    Text("NOW")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.primary))
                }

                Spacer()

                Button { viewModel.nextMonth() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.5))
                }
            }

            CalendarGridView(
                selectedMonth: viewModel.selectedMonth,
                dailyTotals: viewModel.dailyTotals
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Formatting

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp0"
    }
}
