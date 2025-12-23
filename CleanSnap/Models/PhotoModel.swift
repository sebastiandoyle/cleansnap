import Foundation
import Photos
import UIKit

struct PhotoAsset: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let creationDate: Date?
    let fileSize: Int64
    let pixelWidth: Int
    let pixelHeight: Int
    let mediaType: PHAssetMediaType
    var isSelected: Bool = false

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.creationDate = asset.creationDate
        self.pixelWidth = asset.pixelWidth
        self.pixelHeight = asset.pixelHeight
        self.mediaType = asset.mediaType

        let resources = PHAssetResource.assetResources(for: asset)
        self.fileSize = resources.first.flatMap { resource in
            (resource.value(forKey: "fileSize") as? Int64)
        } ?? 0
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        lhs.id == rhs.id
    }
}

struct DuplicateGroup: Identifiable {
    let id = UUID()
    var photos: [PhotoAsset]
    let similarity: Double

    var potentialSavings: Int64 {
        guard photos.count > 1 else { return 0 }
        return photos.dropFirst().reduce(0) { $0 + $1.fileSize }
    }
}

struct SimilarPhotosGroup: Identifiable {
    let id = UUID()
    var photos: [PhotoAsset]
    let dateTaken: Date?
}

enum CleanupCategory: String, CaseIterable, Identifiable {
    case duplicates = "Duplicates"
    case similar = "Similar Photos"
    case screenshots = "Screenshots"
    case largeFiles = "Large Files"
    case videos = "Videos"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .duplicates: return "doc.on.doc.fill"
        case .similar: return "square.on.square"
        case .screenshots: return "camera.viewfinder"
        case .largeFiles: return "arrow.up.circle.fill"
        case .videos: return "video.fill"
        }
    }

    var color: String {
        switch self {
        case .duplicates: return "blue"
        case .similar: return "purple"
        case .screenshots: return "orange"
        case .largeFiles: return "red"
        case .videos: return "green"
        }
    }
}

struct StorageInfo {
    let totalSpace: Int64
    let usedSpace: Int64
    let freeSpace: Int64
    let photoLibrarySize: Int64

    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }
}

struct Contact: Identifiable {
    let id: String
    let givenName: String
    let familyName: String
    let phoneNumbers: [String]
    let emailAddresses: [String]

    var fullName: String {
        "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
    }
}

struct DuplicateContactGroup: Identifiable {
    let id = UUID()
    var contacts: [Contact]
}
