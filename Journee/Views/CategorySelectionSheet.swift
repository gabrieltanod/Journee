import SwiftUI
import SwiftData

struct CategorySelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: DashboardViewModel
    @Binding var selectedCategory: Category?

    @State private var expandedHeadCategories: Set<UUID> = []
    @State private var showAddHeadCategory: Bool = false
    @State private var targetHeadCategory: HeadCategory? = nil
    @State private var categoryToEdit: Category? = nil
    @State private var headCategoryToEdit: HeadCategory? = nil

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
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            if selectedCategory?.id == category.id {
                                                selectedCategory = nil
                                            }
                                            viewModel.deleteCategory(category)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            categoryToEdit = category
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
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

                            Button {
                                headCategoryToEdit = head
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
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
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        if selectedCategory?.id == category.id {
                                            selectedCategory = nil
                                        }
                                        viewModel.deleteCategory(category)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        categoryToEdit = category
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
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
            .sheet(item: $categoryToEdit) { category in
                EditCategorySheet(viewModel: viewModel, category: category)
                    .presentationDetents([.large])
            }
            .sheet(item: $headCategoryToEdit) { head in
                EditHeadCategorySheet(viewModel: viewModel, headCategory: head)
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
