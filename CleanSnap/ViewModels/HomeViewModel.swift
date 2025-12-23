import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var storageInfo: StorageInfo?
    @Published var isLoading = false
    @Published var error: String?

    private let storageAnalyzer = StorageAnalyzer.shared
    private let photoManager = PhotoManager.shared
    private let duplicateDetector = DuplicateDetector.shared

    var totalDuplicates: Int {
        duplicateDetector.totalDuplicatesFound
    }

    var similarGroupsCount: Int {
        duplicateDetector.similarGroups.count
    }

    var screenshotsCount: Int {
        photoManager.screenshots.count
    }

    var largeFilesCount: Int {
        photoManager.largeFiles.count
    }

    var potentialSavings: Int64 {
        duplicateDetector.potentialSpaceSaved
    }

    var scanProgress: Double {
        if photoManager.isLoading {
            return photoManager.loadingProgress * 0.5
        } else if duplicateDetector.isScanning {
            return 0.5 + duplicateDetector.scanProgress * 0.5
        }
        return 1.0
    }

    var isScanning: Bool {
        photoManager.isLoading || duplicateDetector.isScanning
    }

    func loadData() async {
        isLoading = true
        error = nil

        storageInfo = storageAnalyzer.getStorageInfo()

        if photoManager.authorizationStatus != .authorized {
            let granted = await photoManager.requestAuthorization()
            if !granted {
                error = "Photo library access is required to scan for duplicates."
                isLoading = false
                return
            }
        }

        await photoManager.loadAllPhotos()
        await duplicateDetector.scanForDuplicates(photos: photoManager.allPhotos)
        await duplicateDetector.scanForSimilarPhotos(photos: photoManager.allPhotos)

        isLoading = false
    }

    func refreshData() async {
        await loadData()
    }

    func formatStorage(_ bytes: Int64) -> String {
        storageAnalyzer.formatBytes(bytes)
    }
}
