import SwiftUI

struct ContactsView: View {
    @StateObject private var contactManager = ContactManager.shared
    @EnvironmentObject var storeManager: StoreManager
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if contactManager.authorizationStatus != .authorized {
                    permissionRequiredView
                } else if contactManager.isLoading {
                    loadingView
                } else if contactManager.duplicateGroups.isEmpty {
                    emptyStateView
                } else {
                    duplicateContactsList
                }
            }
            .navigationTitle("Contacts")
            .task {
                if contactManager.authorizationStatus == .authorized {
                    await contactManager.loadContacts()
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var permissionRequiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("Contact Access Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("Allow CleanSnap to access your contacts to find and merge duplicates.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await contactManager.requestAuthorization()
                    if contactManager.authorizationStatus == .authorized {
                        await contactManager.loadContacts()
                    }
                }
            } label: {
                Text("Grant Access")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Scanning contacts...")
                .font(.headline)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("No Duplicate Contacts")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your contacts are organized!")
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await contactManager.loadContacts()
                }
            } label: {
                Label("Scan Again", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private var duplicateContactsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                summaryCard

                ForEach(contactManager.duplicateGroups) { group in
                    DuplicateContactCard(
                        group: group,
                        isPremium: storeManager.isPremium,
                        onMerge: { keepIndex in
                            Task {
                                if storeManager.isPremium {
                                    try? await contactManager.mergeContacts(group: group, keepIndex: keepIndex)
                                } else {
                                    showingPaywall = true
                                }
                            }
                        },
                        onUpgradeRequest: { showingPaywall = true }
                    )
                }
            }
            .padding()
        }
    }

    private var summaryCard: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading) {
                Text("\(contactManager.duplicateGroups.count) duplicate groups")
                    .font(.headline)
                Text("\(totalDuplicates) contacts can be merged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var totalDuplicates: Int {
        contactManager.duplicateGroups.reduce(0) { $0 + $1.contacts.count - 1 }
    }
}

struct DuplicateContactCard: View {
    let group: DuplicateContactGroup
    let isPremium: Bool
    let onMerge: (Int) -> Void
    let onUpgradeRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(group.contacts.first?.fullName ?? "Unknown")
                    .font(.headline)

                Spacer()

                Text("\(group.contacts.count) contacts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(group.contacts.enumerated()), id: \.element.id) { index, contact in
                ContactRow(contact: contact, index: index) {
                    if isPremium {
                        onMerge(index)
                    } else {
                        onUpgradeRequest()
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ContactRow: View {
    let contact: Contact
    let index: Int
    let onKeep: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if !contact.phoneNumbers.isEmpty {
                    Label(contact.phoneNumbers.first ?? "", systemImage: "phone.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !contact.emailAddresses.isEmpty {
                    Label(contact.emailAddresses.first ?? "", systemImage: "envelope.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button("Keep") {
                onKeep()
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContactsView()
        .environmentObject(StoreManager())
}
