import SwiftUI

struct BudgetPromptView: View {
    @State private var budgetText: String = ""
    @State private var shake: Bool = false
    var onSave: (Double) -> Void
    var onSkip: (() -> Void)? = nil

    private var isValidAmount: Bool {
        guard let val = Double(budgetText), val > 0 else { return false }
        return true
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.primary.opacity(0.15))

                // Title
                VStack(spacing: 8) {
                    Text("Set Your Budget")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))

                    Text("How much can you spend this month?")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                // Amount input
                VStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("Rp")
                            .font(.system(.title2, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)

                        TextField("0", text: $budgetText)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(.horizontal, 32)

                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 48)
                }
                .modifier(ShakeEffect(shakes: shake ? 2 : 0))

                Spacer()

                // Save button
                Button {
                    if let amount = Double(budgetText), amount > 0 {
                        onSave(amount)
                    } else {
                        withAnimation(.default) {
                            shake = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            shake = false
                        }
                    }
                } label: {
                    Text("Set Budget")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isValidAmount ? Color.primary : Color.primary.opacity(0.2))
                        )
                }
                .padding(.horizontal, 24)

                if let onSkip {
                    Button {
                        onSkip()
                    } label: {
                        Text("Skip")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer().frame(height: 32)
            }
        }
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat

    init(shakes: CGFloat) {
        self.animatableData = shakes
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
