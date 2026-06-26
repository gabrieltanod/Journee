import SwiftUI
import SwiftData

struct WalletsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WalletsViewModel?

    var body: some View {
        Group {
            if let viewModel {
                WalletsContent(viewModel: viewModel)
            } else {
                Color(.systemBackground)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WalletsViewModel(modelContext: modelContext)
            } else {
                viewModel?.loadWallets()
            }
        }
    }
}

// MARK: - Content

struct WalletsContent: View {
    @Bindable var viewModel: WalletsViewModel

    @State private var showAddWallet: Bool = false
    @State private var walletToEdit: Wallet?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(viewModel.wallets, id: \.id) { wallet in
                        NavigationLink(value: wallet.id) {
                            WalletCard(wallet: wallet)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if !wallet.isDefault {
                                Button {
                                    walletToEdit = wallet
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                            }
                        }
                    }

                    // Add wallet button
                    Button {
                        showAddWallet = true
                    } label: {
                        VStack {
                            Spacer()

                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(.secondary)

                            Text("Add Wallet")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color(.tertiarySystemFill))
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 80)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Wallets")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: UUID.self) { walletID in
                if let wallet = viewModel.wallets.first(where: { $0.id == walletID }) {
                    WalletDetailView(viewModel: viewModel, wallet: wallet)
                }
            }
            .sheet(isPresented: $showAddWallet) {
                AddWalletSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .sheet(item: $walletToEdit) { wallet in
                AddWalletSheet(viewModel: viewModel, existingWallet: wallet)
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Wallet Card

struct WalletCard: View {
    let wallet: Wallet

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: emoji + name
            HStack(spacing: 6) {
                Text(wallet.emoji)
                    .font(.system(size: 20))

                Text(wallet.name)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()

            // Bottom: balance
            Text(wallet.calculatedBalance.formattedRupiah)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: wallet.colorHex))
        )
        .shadow(color: Color(hex: wallet.colorHex).opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
