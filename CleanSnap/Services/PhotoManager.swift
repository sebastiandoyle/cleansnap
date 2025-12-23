import Foundation
import Photos
import UIKit

@MainActor
class PhotoManager: ObservableObject {
    static let shared = PhotoManager()

    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var allPhotos: [PhotoAsset] = []
    @Published var screenshots: [PhotoAsset] = []
    @Published var largeFiles: [PhotoAsset] = []
    @Published var videos: [PhotoAsset] = []
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0

    private let imageManager = PHCachingImageManager()

    private init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authorizationStatus = status
        }
        return status == .authorized || status == .limited
    }

    func loadAllPhotos() async {
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            return
        }

        await MainActor.run {
            isLoading = true
            loadingProgress = 0
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let allPhotosResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let allVideosResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)

        var photos: [PhotoAsset] = []
        var screenshotsList: [PhotoAsset] = []
        var largeFilesList: [PhotoAsset] = []
        var videosList: [PhotoAsset] = []

        let totalCount = allPhotosResult.count + allVideosResult.count

        allPhotosResult.enumerateObjects { asset, index, _ in
            let photoAsset = PhotoAsset(asset: asset)
            photos.append(photoAsset)

            if asset.mediaSubtypes.contains(.photoScreenshot) {
                screenshotsList.append(photoAsset)
            }

            if photoAsset.fileSize > 5_000_000 {
                largeFilesList.append(photoAsset)
            }

            if index % 100 == 0 {
                Task { @MainActor in
                    self.loadingProgress = Double(index) / Double(totalCount)
                }
            }
        }

        allVideosResult.enumerateObjects { asset, index, _ in
            let photoAsset = PhotoAsset(asset: asset)
            videosList.append(photoAsset)

            if photoAsset.fileSize > 50_000_000 {
                largeFilesList.append(photoAsset)
            }
        }

        largeFilesList.sort { $0.fileSize > $1.fileSize }

        await MainActor.run {
            self.allPhotos = photos
            self.screenshots = screenshotsList
            self.largeFiles = largeFilesList
            self.videos = videosList
            self.isLoading = false
            self.loadingProgress = 1.0
        }
    }

    func loadThumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = true

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    func loadFullImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    func deleteAssets(_ assets: [PhotoAsset]) async throws {
        let phAssets = assets.map { $0.asset }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(phAssets as NSFastEnumeration)
        }

        await MainActor.run {
            let idsToRemove = Set(assets.map { $0.id })
            self.allPhotos.removeAll { idsToRemove.contains($0.id) }
            self.screenshots.removeAll { idsToRemove.contains($0.id) }
            self.largeFiles.removeAll { idsToRemove.contains($0.id) }
            self.videos.removeAll { idsToRemove.contains($0.id) }
        }
    }

    func getImageData(for asset: PHAsset) async -> Data? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
