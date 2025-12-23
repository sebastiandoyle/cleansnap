import Foundation
import UIKit
import Security

@MainActor
class VaultManager: ObservableObject {
    static let shared = VaultManager()

    @Published var isLocked = true
    @Published var vaultPhotos: [VaultPhoto] = []
    @Published var hasSetupPIN = false

    private let pinKey = "com.cleansnap.vault.pin"
    private let vaultDirectory: URL

    struct VaultPhoto: Identifiable {
        let id: UUID
        let imageData: Data
        let dateAdded: Date
    }

    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        vaultDirectory = documentsPath.appendingPathComponent("SecretVault", isDirectory: true)

        createVaultDirectoryIfNeeded()
        checkPINSetup()
        loadVaultPhotos()
    }

    private func createVaultDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: vaultDirectory.path) {
            try? FileManager.default.createDirectory(at: vaultDirectory, withIntermediateDirectories: true)
        }
    }

    private func checkPINSetup() {
        hasSetupPIN = loadPIN() != nil
    }

    func setupPIN(_ pin: String) -> Bool {
        guard pin.count == 4, pin.allSatisfy({ $0.isNumber }) else { return false }
        return savePIN(pin)
    }

    func verifyPIN(_ pin: String) -> Bool {
        guard let storedPIN = loadPIN() else { return false }
        let isValid = pin == storedPIN
        if isValid {
            isLocked = false
        }
        return isValid
    }

    func lock() {
        isLocked = true
    }

    func changePIN(oldPIN: String, newPIN: String) -> Bool {
        guard verifyPIN(oldPIN) else { return false }
        return savePIN(newPIN)
    }

    private func savePIN(_ pin: String) -> Bool {
        guard let data = pin.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        hasSetupPIN = status == errSecSuccess
        return status == errSecSuccess
    }

    private func loadPIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: pinKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let pin = String(data: data, encoding: .utf8) else {
            return nil
        }

        return pin
    }

    func addPhotoToVault(_ imageData: Data) {
        let photo = VaultPhoto(
            id: UUID(),
            imageData: imageData,
            dateAdded: Date()
        )

        let fileURL = vaultDirectory.appendingPathComponent("\(photo.id.uuidString).jpg")
        try? imageData.write(to: fileURL)

        vaultPhotos.append(photo)
        saveVaultMetadata()
    }

    func removePhotoFromVault(_ photo: VaultPhoto) {
        let fileURL = vaultDirectory.appendingPathComponent("\(photo.id.uuidString).jpg")
        try? FileManager.default.removeItem(at: fileURL)

        vaultPhotos.removeAll { $0.id == photo.id }
        saveVaultMetadata()
    }

    private func loadVaultPhotos() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: vaultDirectory,
            includingPropertiesForKeys: [.creationDateKey]
        ) else { return }

        vaultPhotos = files.compactMap { url -> VaultPhoto? in
            guard url.pathExtension == "jpg",
                  let data = try? Data(contentsOf: url),
                  let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent),
                  let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let date = attributes[.creationDate] as? Date else {
                return nil
            }
            return VaultPhoto(id: id, imageData: data, dateAdded: date)
        }
    }

    private func saveVaultMetadata() {
        // Metadata is stored in file system attributes
    }
}
