import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel?
    @State private var showFileImporter: Bool = false

    var body: some View {
        Group {
            if let viewModel {
                settingsContent(viewModel: viewModel)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SettingsViewModel(modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func settingsContent(viewModel: SettingsViewModel) -> some View {
        List {
            // MARK: - Backup Section
            Section {
                // Export
                Button {
                    viewModel.exportBackup()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(hex: "4ECDC4"))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Backup")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(.primary)

                            Text("Save all data as a JSON file")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Import
                Button {
                    showFileImporter = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(hex: "A78BFA"))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import Backup")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundStyle(.primary)

                            Text("Restore from a JSON backup file")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Backup & Restore")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            } footer: {
                Text("Exporting creates a snapshot of all your categories, transactions, and budgets. Importing merges new data without overwriting existing entries.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            // MARK: - About Section
            Section {
                HStack {
                    Text("App")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Journee")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Data Format")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("JSON v1")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importBackup(from: url)
                }
            case .failure(let error):
                viewModel.errorMessage = "Could not open file: \(error.localizedDescription)"
                viewModel.showErrorAlert = true
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.isExporting && viewModel.exportURL != nil },
            set: { if !$0 { viewModel.isExporting = false } }
        )) {
            if let url = viewModel.exportURL {
                ShareSheetView(activityItems: [url])
            }
        }
        .alert("Import Complete", isPresented: Binding(
            get: { viewModel.showImportAlert },
            set: { viewModel.showImportAlert = $0 }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.importSummary)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.showErrorAlert },
            set: { viewModel.showErrorAlert = $0 }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }
}

// MARK: - UIKit Share Sheet Wrapper

struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
