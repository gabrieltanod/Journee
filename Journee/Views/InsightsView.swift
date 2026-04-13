import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("payday") private var payday: Int = 1
    @State private var viewModel: InsightsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                InsightsContent(viewModel: viewModel)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = InsightsViewModel(modelContext: modelContext, payday: payday)
            }
        }
        .onChange(of: payday) { _, newValue in
            viewModel?.updatePayday(newValue)
        }
    }
}

// MARK: - Content

struct InsightsContent: View {
    @Bindable var viewModel: InsightsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    cycleNavigator
                    donutChartCard
                    categoryListCard

                    // Total Income section
                    if viewModel.totalIncome > 0 {
                        incomeCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Cycle Navigator

    private var cycleNavigator: some View {
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Donut Chart

    private var donutChartCard: some View {
        VStack(spacing: 16) {
            if viewModel.categoryBreakdown.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 40))
                        .foregroundStyle(.primary.opacity(0.15))

                    Text("No expenses this cycle")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(height: 260)
                .frame(maxWidth: .infinity)
            } else {
                Chart(viewModel.categoryBreakdown) { slice in
                    SectorMark(
                        angle: .value("Amount", slice.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.color)
                    .cornerRadius(4)
                    .opacity(selectedOpacity(for: slice))
                }
                .chartAngleSelection(value: $chartAngleSelection)
                .frame(height: 260)
                .overlay {
                    donutCenter
                }
                .animation(.easeInOut(duration: 0.25), value: viewModel.selectedSlice)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .onChange(of: chartAngleSelection) { _, newValue in
            withAnimation(.easeInOut(duration: 0.25)) {
                selectSlice(for: newValue)
            }
        }
    }

    @State private var chartAngleSelection: Double?

    private func selectedOpacity(for slice: CategorySlice) -> Double {
        guard let selected = viewModel.selectedSlice else { return 1.0 }
        return slice.name == selected.name ? 1.0 : 0.4
    }

    private func selectSlice(for value: Double?) {
        guard let value else {
            viewModel.selectedSlice = nil
            return
        }

        var cumulative: Double = 0
        for slice in viewModel.categoryBreakdown {
            cumulative += slice.amount
            if value <= cumulative {
                viewModel.selectedSlice = slice
                return
            }
        }
    }

    private var donutCenter: some View {
        VStack(spacing: 4) {
            if let selected = viewModel.selectedSlice {
                Image(systemName: selected.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(selected.color)

                Text(selected.name)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(formattedCurrency(selected.amount))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
            } else {
                Text("Total")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(formattedCurrency(viewModel.totalSpent))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
            }
        }
        .contentTransition(.numericText())
    }

    // MARK: - Category List

    private var categoryListCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.categoryBreakdown.enumerated()), id: \.element.id) { index, slice in
                NavigationLink {
                    CategoryDetailView(
                        categoryName: slice.name,
                        categoryIcon: slice.icon,
                        categoryColorHex: slice.colorHex,
                        cycle: viewModel.currentCycle
                    )
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 10, height: 10)

                        Image(systemName: slice.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(slice.color)
                            .frame(width: 24)

                        Text(slice.name)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(formattedCurrency(slice.amount))
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.25))
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)

                if index < viewModel.categoryBreakdown.count - 1 {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Income Card

    private var incomeCard: some View {
        NavigationLink {
            CategoryDetailView(
                categoryName: "Income",
                categoryIcon: "banknote.fill",
                categoryColorHex: "22C55E",
                cycle: viewModel.currentCycle
            )
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "22C55E"))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Income")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.primary)

                    Text("This cycle")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formattedCurrency(viewModel.totalIncome))
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(Color(hex: "22C55E"))

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.25))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "22C55E").opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(hex: "22C55E").opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp0"
    }
}
