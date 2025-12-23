import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .weekly
    @State private var isPurchasing = false

    enum SubscriptionPlan {
        case weekly
        case lifetime
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    featuresSection

                    plansSection

                    purchaseButton

                    legalText
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("Unlock Premium")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Get unlimited access to all features")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var featuresSection: some View {
        VStack(spacing: 12) {
            FeatureRow(icon: "doc.on.doc.fill", title: "Unlimited Duplicate Detection", color: .blue)
            FeatureRow(icon: "square.on.square", title: "Similar Photos Cleanup", color: .purple)
            FeatureRow(icon: "lock.fill", title: "Secret Vault", color: .orange)
            FeatureRow(icon: "person.2.fill", title: "Contact Merger", color: .green)
            FeatureRow(icon: "sparkles", title: "Priority Support", color: .pink)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var plansSection: some View {
        VStack(spacing: 12) {
            PlanCard(
                title: "Weekly",
                price: storeManager.weeklyProduct?.displayPrice ?? "$4.99",
                period: "per week",
                isSelected: selectedPlan == .weekly,
                badge: "7-Day Free Trial"
            ) {
                selectedPlan = .weekly
            }

            PlanCard(
                title: "Lifetime",
                price: storeManager.lifetimeProduct?.displayPrice ?? "$29.99",
                period: "one-time purchase",
                isSelected: selectedPlan == .lifetime,
                badge: "Best Value"
            ) {
                selectedPlan = .lifetime
            }
        }
    }

    private var purchaseButton: some View {
        Button {
            Task {
                await purchase()
            }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(selectedPlan == .weekly ? "Start Free Trial" : "Purchase")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isPurchasing)
    }

    private var legalText: some View {
        VStack(spacing: 8) {
            if selectedPlan == .weekly {
                Text("After your 7-day free trial, you'll be charged \(storeManager.weeklyProduct?.displayPrice ?? "$4.99") per week. Cancel anytime.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                Button("Terms of Service") {}
                    .font(.caption2)
                Button("Privacy Policy") {}
                    .font(.caption2)
                Button("Restore") {
                    Task {
                        await storeManager.restorePurchases()
                    }
                }
                .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
    }

    private func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        let product: Product?
        switch selectedPlan {
        case .weekly:
            product = storeManager.weeklyProduct
        case .lifetime:
            product = storeManager.lifetimeProduct
        }

        guard let product = product else { return }

        if let success = try? await storeManager.purchase(product), success {
            dismiss()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)

            Text(title)
                .font(.subheadline)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

struct PlanCard: View {
    let title: String
    let price: String
    let period: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }

                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .gray)
            }
            .padding()
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(StoreManager())
}
