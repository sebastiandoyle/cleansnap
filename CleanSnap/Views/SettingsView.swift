import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var storeManager: StoreManager
    @State private var showingPaywall = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = true

    var body: some View {
        NavigationStack {
            List {
                premiumSection

                featuresSection

                aboutSection

                legalSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var premiumSection: some View {
        Section {
            if storeManager.isPremium {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("Premium Active")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        Text("Upgrade to Premium")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                Task {
                    await storeManager.restorePurchases()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Restore Purchases")
                }
            }
        } header: {
            Text("Subscription")
        }
    }

    private var featuresSection: some View {
        Section {
            NavigationLink {
                ContactsView()
            } label: {
                Label("Duplicate Contacts", systemImage: "person.2.fill")
            }

            Button {
                hasSeenOnboarding = false
            } label: {
                Label("Show Onboarding", systemImage: "hand.wave.fill")
            }
        } header: {
            Text("Features")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "mailto:support@cleansnap.app")!) {
                Label("Contact Support", systemImage: "envelope.fill")
            }

            Link(destination: URL(string: "https://cleansnap.app")!) {
                Label("Visit Website", systemImage: "globe")
            }
        } header: {
            Text("About")
        }
    }

    private var legalSection: some View {
        Section {
            Link(destination: URL(string: "https://cleansnap.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            Link(destination: URL(string: "https://cleansnap.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text.fill")
            }
        } header: {
            Text("Legal")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreManager())
}
