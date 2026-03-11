import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
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
                viewModel = InsightsViewModel(modelContext: modelContext)
            }
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
                    monthNavigator
                    donutChartCard
                    categoryListCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Month Navigator

    private var monthNavigator: some View {
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

                    Text("No expenses this month")
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
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if viewModel.selectedSlice?.name == slice.name {
                            viewModel.selectedSlice = nil
                        } else {
                            viewModel.selectedSlice = slice
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        // Color dot
                        Circle()
                            .fill(slice.color)
                            .frame(width: 10, height: 10)

                        // Icon + name
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
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(
                        viewModel.selectedSlice?.name == slice.name
                            ? Color.primary.opacity(0.05)
                            : Color.clear
                    )
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

    // MARK: - Helpers

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Rp"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "Rp0"
    }
}
