import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("payday") private var payday: Int = 1
    @AppStorage("geminiAPIKey") private var geminiAPIKey: String = ""
    @State private var viewModel: InsightsViewModel?
    @State private var aiViewModel: InsightsAIViewModel?

    var body: some View {
        Group {
            if let viewModel, let aiViewModel {
                InsightsContent(viewModel: viewModel, aiViewModel: aiViewModel, geminiAPIKey: geminiAPIKey)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = InsightsViewModel(modelContext: modelContext, payday: payday)
            }
            if aiViewModel == nil {
                aiViewModel = InsightsAIViewModel(modelContext: modelContext, payday: payday)
            }
        }
        .onChange(of: payday) { _, newValue in
            viewModel?.updatePayday(newValue)
            aiViewModel?.updatePayday(newValue)
        }
    }
}

// MARK: - Content

struct InsightsContent: View {
    @Bindable var viewModel: InsightsViewModel
    @Bindable var aiViewModel: InsightsAIViewModel
    var geminiAPIKey: String
    @State private var expandedHeadCategories: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    cycleNavigator
                    groupingPicker
                    donutChartCard

                    // List — switches between accordion and flat
                    if viewModel.groupingMode == .headCategories {
                        headCategoryListCard
                    } else {
                        categoryListCard
                    }

                    // Total Income section
                    if viewModel.totalIncome > 0 {
                        incomeCard
                    }

                    // Journee AI Audit
                    aiAuditCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Grouping Picker

    private var groupingPicker: some View {
        Picker("Grouping", selection: $viewModel.groupingMode) {
            ForEach(InsightsGrouping.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
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
            let slices = viewModel.activeChartSlices

            if slices.isEmpty {
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
                Chart(slices) { slice in
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
                .animation(.easeInOut(duration: 0.25), value: viewModel.activeSelectedSlice)
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
        guard let selected = viewModel.activeSelectedSlice else { return 1.0 }
        return slice.name == selected.name ? 1.0 : 0.4
    }

    private func selectSlice(for value: Double?) {
        guard let value else {
            viewModel.selectActiveSlice(nil)
            return
        }

        var cumulative: Double = 0
        for slice in viewModel.activeChartSlices {
            cumulative += slice.amount
            if value <= cumulative {
                viewModel.selectActiveSlice(slice)
                return
            }
        }
    }

    private var donutCenter: some View {
        VStack(spacing: 4) {
            if let selected = viewModel.activeSelectedSlice {
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

    // MARK: - State B: Flat Category List (original)

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
                    flatCategoryRow(slice: slice)
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

    private func flatCategoryRow(slice: CategorySlice) -> some View {
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

    // MARK: - State A: Head Category Accordion List

    private var headCategoryListCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.headCategoryBreakdown.enumerated()), id: \.element.id) { index, headSlice in
                if headSlice.isStandalone {
                    // Standalone category — render as a flat row with navigation
                    if let child = headSlice.children.first {
                        NavigationLink {
                            CategoryDetailView(
                                categoryName: child.name,
                                categoryIcon: child.icon,
                                categoryColorHex: child.colorHex,
                                cycle: viewModel.currentCycle
                            )
                        } label: {
                            flatCategoryRow(slice: CategorySlice(
                                name: headSlice.name,
                                amount: headSlice.totalAmount,
                                icon: headSlice.icon,
                                colorHex: headSlice.colorHex
                            ))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    // Head category — render as a DisclosureGroup
                    DisclosureGroup(
                        isExpanded: expandedBinding(for: headSlice.name)
                    ) {
                        ForEach(headSlice.children) { child in
                            NavigationLink {
                                CategoryDetailView(
                                    categoryName: child.name,
                                    categoryIcon: child.icon,
                                    categoryColorHex: child.colorHex,
                                    cycle: viewModel.currentCycle
                                )
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(child.color)
                                        .frame(width: 8, height: 8)

                                    Image(systemName: child.icon)
                                        .font(.system(size: 13))
                                        .foregroundStyle(child.color)
                                        .frame(width: 22)

                                    Text(child.name)
                                        .font(.system(.caption, design: .rounded, weight: .medium))
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text(formattedCurrency(child.amount))
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .foregroundStyle(.primary)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.primary.opacity(0.2))
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(hex: headSlice.colorHex))
                                .frame(width: 10, height: 10)

                            Image(systemName: headSlice.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: headSlice.colorHex))
                                .frame(width: 24)

                            Text(headSlice.name)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.primary)

                            Spacer()

                            Text(formattedCurrency(headSlice.totalAmount))
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .tint(.secondary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                }

                if index < viewModel.headCategoryBreakdown.count - 1 {
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

    private func expandedBinding(for name: String) -> Binding<Bool> {
        Binding(
            get: { expandedHeadCategories.contains(name) },
            set: { isExpanded in
                if isExpanded {
                    expandedHeadCategories.insert(name)
                } else {
                    expandedHeadCategories.remove(name)
                }
            }
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

    // MARK: - Journee AI Audit Card

    private var aiAuditCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "818CF8"), Color(hex: "6366F1")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Journee AI")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Cycle spending audit")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            // Content — state-driven
            Group {
                if geminiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    aiMissingKeyView
                } else if aiViewModel.isLoading {
                    aiLoadingView
                } else if let errorMsg = aiViewModel.errorMessage {
                    aiErrorView(message: errorMsg)
                } else if !aiViewModel.aiAudit.isEmpty {
                    aiResultView
                } else {
                    aiGenerateButton
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(hex: "818CF8").opacity(0.12), lineWidth: 1)
        )
        .onChange(of: viewModel.currentCycle) { _, newCycle in
            aiViewModel.updateCycle(newCycle)
        }
    }

    // MARK: AI States

    private var aiMissingKeyView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: "F59E0B"))

            Text("Please add your Gemini API Key in Settings to enable AI Audits.")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "F59E0B").opacity(0.08))
        )
    }

    private var aiGenerateButton: some View {
        Button {
            Task {
                await aiViewModel.generateAudit(apiKey: geminiAPIKey)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))

                Text("Generate Cycle Audit")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "818CF8"), Color(hex: "6366F1")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var aiLoadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.regular)
                .tint(Color(hex: "818CF8"))

            Text("Analyzing your spending…")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var aiResultView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(aiViewModel.aiAudit)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // Regenerate button
            Button {
                Task {
                    aiViewModel.aiAudit = ""
                    await aiViewModel.generateAudit(apiKey: geminiAPIKey)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.trianglehead.2.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))

                    Text("Regenerate")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "6366F1"))
                .padding(.top, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "818CF8").opacity(0.06))
        )
    }

    private func aiErrorView(message: String) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "EF4444"))

                Text(message)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task {
                    await aiViewModel.generateAudit(apiKey: geminiAPIKey)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))

                    Text("Retry")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "EF4444"))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "EF4444").opacity(0.06))
        )
    }

    // MARK: - Helpers

    private func formattedCurrency(_ value: Double) -> String {
        return value.formattedRupiah
    }
}
