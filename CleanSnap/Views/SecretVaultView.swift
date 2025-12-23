import SwiftUI
import PhotosUI

struct SecretVaultView: View {
    @StateObject private var vaultManager = VaultManager.shared
    @EnvironmentObject var storeManager: StoreManager
    @State private var pinInput = ""
    @State private var showingSetupPIN = false
    @State private var showingPhotoPicker = false
    @State private var showingPaywall = false
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Group {
                if !storeManager.isPremium {
                    premiumRequired
                } else if !vaultManager.hasSetupPIN {
                    setupPINView
                } else if vaultManager.isLocked {
                    lockedView
                } else {
                    unlockedVaultView
                }
            }
            .navigationTitle("Secret Vault")
            .toolbar {
                if !vaultManager.isLocked && vaultManager.hasSetupPIN && storeManager.isPremium {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            vaultManager.lock()
                        } label: {
                            Image(systemName: "lock.fill")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingPhotoPicker = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedItems, matching: .images)
            .onChange(of: selectedItems) { _, items in
                Task {
                    await addPhotosToVault(items)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var premiumRequired: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(.gray)

            Text("Premium Feature")
                .font(.title)
                .fontWeight(.bold)

            Text("Secret Vault is a premium feature.\nUpgrade to hide your private photos behind a secure PIN.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingPaywall = true
            } label: {
                Text("Upgrade to Premium")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
    }

    private var setupPINView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Set Up Your PIN")
                .font(.title)
                .fontWeight(.bold)

            Text("Create a 4-digit PIN to protect your private photos")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            PINInputView(pin: $pinInput, length: 4)
                .shake(trigger: showError)

            Button {
                if vaultManager.setupPIN(pinInput) {
                    pinInput = ""
                } else {
                    showError = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showError = false
                    }
                }
            } label: {
                Text("Set PIN")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pinInput.count == 4 ? Color.blue : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(pinInput.count != 4)
            .padding(.horizontal, 40)
        }
    }

    private var lockedView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)

            Text("Vault Locked")
                .font(.title)
                .fontWeight(.bold)

            Text("Enter your PIN to access your private photos")
                .font(.body)
                .foregroundStyle(.secondary)

            PINInputView(pin: $pinInput, length: 4)
                .shake(trigger: showError)

            Button {
                if vaultManager.verifyPIN(pinInput) {
                    pinInput = ""
                } else {
                    showError = true
                    pinInput = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showError = false
                    }
                }
            } label: {
                Text("Unlock")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pinInput.count == 4 ? Color.blue : Color.gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(pinInput.count != 4)
            .padding(.horizontal, 40)
        }
    }

    private var unlockedVaultView: some View {
        Group {
            if vaultManager.vaultPhotos.isEmpty {
                emptyVaultView
            } else {
                vaultPhotoGrid
            }
        }
    }

    private var emptyVaultView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("Your Vault is Empty")
                .font(.title2)
                .fontWeight(.bold)

            Text("Tap + to add photos to your secret vault")
                .foregroundStyle(.secondary)

            Button {
                showingPhotoPicker = true
            } label: {
                Label("Add Photos", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    private var vaultPhotoGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 4) {
                ForEach(vaultManager.vaultPhotos) { photo in
                    VaultPhotoThumbnail(photo: photo) {
                        vaultManager.removePhotoFromVault(photo)
                    }
                }
            }
            .padding(4)
        }
    }

    private func addPhotosToVault(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    vaultManager.addPhotoToVault(data)
                }
            }
        }
        selectedItems.removeAll()
    }
}

struct PINInputView: View {
    @Binding var pin: String
    let length: Int

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<length, id: \.self) { index in
                Circle()
                    .fill(index < pin.count ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 20)
        .overlay {
            TextField("", text: $pin)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .opacity(0.01)
                .onChange(of: pin) { _, newValue in
                    if newValue.count > length {
                        pin = String(newValue.prefix(length))
                    }
                    pin = newValue.filter { $0.isNumber }
                }
        }
    }
}

struct VaultPhotoThumbnail: View {
    let photo: VaultManager.VaultPhoto
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false

    var body: some View {
        Group {
            if let image = UIImage(data: photo.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
        }
        .frame(minHeight: 120)
        .clipped()
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Remove from vault?", isPresented: $showingDeleteConfirmation) {
            Button("Remove", role: .destructive, action: onDelete)
        }
    }
}

#Preview {
    SecretVaultView()
        .environmentObject(StoreManager())
}
