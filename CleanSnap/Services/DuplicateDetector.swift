import Foundation
import Photos
import UIKit
import CryptoKit

@MainActor
class DuplicateDetector: ObservableObject {
    static let shared = DuplicateDetector()

    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var similarGroups: [SimilarPhotosGroup] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var totalDuplicatesFound = 0
    @Published var potentialSpaceSaved: Int64 = 0

    private init() {}

    func scanForDuplicates(photos: [PhotoAsset]) async {
        await MainActor.run {
            isScanning = true
            scanProgress = 0
            duplicateGroups = []
        }

        var hashGroups: [String: [PhotoAsset]] = [:]
        let total = photos.count

        for (index, photo) in photos.enumerated() {
            if let hash = await computePerceptualHash(for: photo) {
                if hashGroups[hash] != nil {
                    hashGroups[hash]?.append(photo)
                } else {
                    hashGroups[hash] = [photo]
                }
            }

            if index % 50 == 0 {
                await MainActor.run {
                    self.scanProgress = Double(index) / Double(total) * 0.8
                }
            }
        }

        let duplicates = hashGroups.filter { $0.value.count > 1 }
            .map { DuplicateGroup(photos: $0.value, similarity: 1.0) }
            .sorted { $0.potentialSavings > $1.potentialSavings }

        let totalSavings = duplicates.reduce(0) { $0 + $1.potentialSavings }

        await MainActor.run {
            self.duplicateGroups = duplicates
            self.totalDuplicatesFound = duplicates.reduce(0) { $0 + $1.photos.count - 1 }
            self.potentialSpaceSaved = totalSavings
            self.scanProgress = 1.0
            self.isScanning = false
        }
    }

    func scanForSimilarPhotos(photos: [PhotoAsset]) async {
        await MainActor.run {
            isScanning = true
            scanProgress = 0
            similarGroups = []
        }

        var dateGroups: [String: [PhotoAsset]] = [:]

        for photo in photos {
            guard let date = photo.creationDate else { continue }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HH"
            let key = formatter.string(from: date)

            if dateGroups[key] != nil {
                dateGroups[key]?.append(photo)
            } else {
                dateGroups[key] = [photo]
            }
        }

        let similar = dateGroups.filter { $0.value.count > 2 }
            .map { SimilarPhotosGroup(photos: $0.value, dateTaken: $0.value.first?.creationDate) }
            .sorted { ($0.photos.count) > ($1.photos.count) }

        await MainActor.run {
            self.similarGroups = similar
            self.scanProgress = 1.0
            self.isScanning = false
        }
    }

    private func computePerceptualHash(for photo: PhotoAsset) async -> String? {
        guard let imageData = await PhotoManager.shared.getImageData(for: photo.asset) else {
            return nil
        }

        let hash = SHA256.hash(data: imageData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func computeSimpleHash(for photo: PhotoAsset) -> String {
        let components = [
            String(photo.pixelWidth),
            String(photo.pixelHeight),
            String(photo.fileSize),
            photo.creationDate?.timeIntervalSince1970.description ?? ""
        ]
        return components.joined(separator: "-")
    }
}
