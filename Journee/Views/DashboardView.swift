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

    @State private var selectedDay: Int?
    @State private var showAddExpense: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    budgetCard
                    calendarSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Journee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .navigationDestination(item: $selectedDay) { day in
                DailyDetailView(
                    viewModel: viewModel,
                    date: dateForDay(day)
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
                    Label(formattedCurrency(viewModel.totalSpent), systemImage: "arrow.up.right")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Label(formattedCurrency(viewModel.budgetAmount), systemImage: "target")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }

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

                    Text(formattedCurrency(viewModel.totalSpent))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                Button {
                    viewModel.showBudgetPrompt = true
                } label: {
                    Label("Set Monthly Budget", systemImage: "plus.circle")
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
                dailyTotals: viewModel.dailyTotals,
                onDayTapped: { day in
                    selectedDay = day
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

    private func dateForDay(_ day: Int) -> Date {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: viewModel.selectedMonth)
        comps.day = day
        return calendar.date(from: comps) ?? viewModel.selectedMonth
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp0"
    }
}
