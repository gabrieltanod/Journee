import SwiftUI
import SwiftData

struct AddWalletSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: WalletsViewModel

    var existingWallet: Wallet? = nil

    @State private var name: String = ""
    @State private var emoji: String = "💰"
    @State private var initialBalanceText: String = ""
    @State private var selectedColorHex: String = "4ECDC4"

    private var isEditing: Bool { existingWallet != nil }

    // Curated color palette
    private let colorOptions: [(name: String, hex: String)] = [
        ("Green", "22C55E"),
        ("Teal", "4ECDC4"),
        ("Blue", "3B82F6"),
        ("Indigo", "6366F1"),
        ("Purple", "A78BFA"),
        ("Pink", "F472B6"),
        ("Rose", "FB7185"),
        ("Orange", "F97316"),
        ("Amber", "FBBF24"),
        ("Slate", "64748B"),
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !emoji.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Preview card
                    previewCard

                    // Emoji
                    VStack(spacing: 8) {
                        Text("Emoji")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("💰", text: $emoji)
                            .font(.system(size: 32))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onChange(of: emoji) { _, newValue in
                                // Limit to single emoji
                                if newValue.count > 1 {
                                    emoji = String(newValue.suffix(1))
                                }
                            }

                        Rectangle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 1)
                    }

                    // Name
                    VStack(spacing: 8) {
                        Text("Name")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("e.g. Savings, Credit Card", text: $name)
                            .font(.system(.body, design: .rounded))
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(.tertiarySystemFill))
                            )
                    }

                    // Initial Balance
                    VStack(spacing: 8) {
                        Text("Initial Balance")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("Rp")
                                .font(.system(.title3, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)

                            TextField("0", text: $initialBalanceText)
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .keyboardType(.numberPad)
                        }

                        Rectangle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 1)
                    }

                    // Color picker
                    VStack(spacing: 8) {
                        Text("Color")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(colorOptions, id: \.hex) { color in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedColorHex = color.hex
                                        }
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: color.hex))
                                            .frame(width: 36, height: 36)
                                            .overlay {
                                                if selectedColorHex == color.hex {
                                                    Circle()
                                                        .strokeBorder(.white, lineWidth: 3)
                                                        .frame(width: 36, height: 36)
                                                    Circle()
                                                        .strokeBorder(Color(hex: color.hex), lineWidth: 1.5)
                                                        .frame(width: 42, height: 42)
                                                }
                                            }
                                            .frame(width: 42, height: 42)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(isEditing ? "Edit Wallet" : "New Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWallet()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .disabled(!isValid)
                }
            }
            .onAppear {
                prefillFields()
            }
        }
    }

    // MARK: - Preview Card

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(emoji.isEmpty ? "💰" : emoji)
                    .font(.system(size: 20))

                Text(name.isEmpty ? "Wallet" : name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            Text((Double(initialBalanceText) ?? 0).formattedRupiah)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: selectedColorHex))
        )
        .shadow(color: Color(hex: selectedColorHex).opacity(0.3), radius: 8, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.2), value: selectedColorHex)
    }

    // MARK: - Prefill

    private func prefillFields() {
        if let wallet = existingWallet {
            name = wallet.name
            emoji = wallet.emoji
            initialBalanceText = wallet.initialBalance == 0 ? "" : String(format: "%.0f", wallet.initialBalance)
            selectedColorHex = wallet.colorHex
        }
    }

    // MARK: - Save

    private func saveWallet() {
        let balance = Double(initialBalanceText) ?? 0
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if let wallet = existingWallet {
            viewModel.updateWallet(
                wallet,
                name: trimmedName,
                emoji: emoji,
                colorHex: selectedColorHex,
                initialBalance: balance
            )
        } else {
            viewModel.addWallet(
                name: trimmedName,
                emoji: emoji,
                colorHex: selectedColorHex,
                initialBalance: balance
            )
        }
        dismiss()
    }
}
