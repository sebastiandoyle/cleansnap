import Foundation

@MainActor
class StorageAnalyzer {
    static let shared = StorageAnalyzer()

    private init() {}

    func getStorageInfo() -> StorageInfo {
        let fileManager = FileManager.default
        guard let attributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSize = attributes[.systemSize] as? Int64,
              let freeSize = attributes[.systemFreeSize] as? Int64 else {
            return StorageInfo(totalSpace: 0, usedSpace: 0, freeSpace: 0, photoLibrarySize: 0)
        }

        let usedSize = totalSize - freeSize
        let photoLibrarySize = estimatePhotoLibrarySize()

        return StorageInfo(
            totalSpace: totalSize,
            usedSpace: usedSize,
            freeSpace: freeSize,
            photoLibrarySize: photoLibrarySize
        )
    }

    private func estimatePhotoLibrarySize() -> Int64 {
        let photoManager = PhotoManager.shared
        let photoSize = photoManager.allPhotos.reduce(0) { $0 + $1.fileSize }
        let videoSize = photoManager.videos.reduce(0) { $0 + $1.fileSize }
        return photoSize + videoSize
    }

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        return formatter.string(fromByteCount: bytes)
    }

    func calculatePotentialSavings(duplicates: [DuplicateGroup], screenshots: [PhotoAsset]) -> Int64 {
        let duplicateSavings = duplicates.reduce(0) { $0 + $1.potentialSavings }
        let screenshotSavings = screenshots.reduce(0) { $0 + $1.fileSize }
        return duplicateSavings + screenshotSavings
    }
}
