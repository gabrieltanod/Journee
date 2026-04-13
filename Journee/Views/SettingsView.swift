import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("payday") private var payday: Int = 1
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false
    @AppStorage("notificationHour") private var notificationHour: Int = 20
    @AppStorage("notificationMinute") private var notificationMinute: Int = 0
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
            // MARK: - Budget Cycle Section
            Section {
                HStack {
                    Text("Payday")
                        .font(.system(.body, design: .rounded, weight: .medium))

                    Spacer()

                    // Minus button
                    Button {
                        if payday > 1 { payday -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.tertiarySystemFill)))
                    }
                    .buttonStyle(.plain)
                    .disabled(payday <= 1)

                    // Editable text field
                    TextField("1", text: Binding(
                        get: { "\(payday)" },
                        set: { newValue in
                            if let val = Int(newValue) {
                                payday = max(1, min(28, val))
                            }
                        }
                    ))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 44)

                    // Plus button
                    Button {
                        if payday < 28 { payday += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color(.tertiarySystemFill)))
                    }
                    .buttonStyle(.plain)
                    .disabled(payday >= 28)
                }

                // Cycle preview
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    Text(cyclePreviewText)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Budget Cycle")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            } footer: {
                Text("Your budget cycle runs from the payday of one month to the day before the next payday. Set to 1 for standard monthly cycles.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

            // MARK: - Daily Reminder Section
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color(hex: "FF6B6B"))
                            )

                        Text("Daily Reminder")
                            .font(.system(.body, design: .rounded, weight: .medium))
                    }
                }
                .onChange(of: notificationsEnabled) { _, enabled in
                    if enabled {
                        NotificationManager.shared.requestAuthorization { granted in
                            if granted {
                                NotificationManager.shared.scheduleDailyReminder(
                                    hour: notificationHour,
                                    minute: notificationMinute
                                )
                            } else {
                                notificationsEnabled = false
                            }
                        }
                    } else {
                        NotificationManager.shared.cancelReminder()
                    }
                }

                if notificationsEnabled {
                    DatePicker(
                        "Remind at",
                        selection: Binding(
                            get: {
                                var comps = DateComponents()
                                comps.hour = notificationHour
                                comps.minute = notificationMinute
                                return Calendar.current.date(from: comps) ?? Date()
                            },
                            set: { newDate in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                notificationHour = comps.hour ?? 20
                                notificationMinute = comps.minute ?? 0
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(.body, design: .rounded))
                    .onChange(of: notificationHour) { _, _ in
                        NotificationManager.shared.scheduleDailyReminder(
                            hour: notificationHour,
                            minute: notificationMinute
                        )
                    }
                    .onChange(of: notificationMinute) { _, _ in
                        NotificationManager.shared.scheduleDailyReminder(
                            hour: notificationHour,
                            minute: notificationMinute
                        )
                    }
                }
            } header: {
                Text("Notifications")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            } footer: {
                Text(notificationsEnabled
                    ? "You'll get a daily reminder to log your expenses."
                    : "Enable to get a daily nudge to track your spending."
                )
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }

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

    // MARK: - Payday Helpers

    private func ordinalDay(_ day: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: day)) ?? "\(day)"
    }

    private var cyclePreviewText: String {
        let cycle = PaydayCycle.cycle(containing: Date(), payday: payday)
        return "Current cycle: \(cycle.label)"
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
