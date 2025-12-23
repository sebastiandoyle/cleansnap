import SwiftUI

struct SimilarPhotosView: View {
    @StateObject private var duplicateDetector = DuplicateDetector.shared
    @StateObject private var photoManager = PhotoManager.shared
    @EnvironmentObject var storeManager: StoreManager
    @State private var selectedPhotos: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if duplicateDetector.isScanning {
                    scanningView
                } else if duplicateDetector.similarGroups.isEmpty {
                    emptyStateView
                } else {
                    similarPhotosList
                }
            }
            .navigationTitle("Similar Photos")
            .toolbar {
                if !duplicateDetector.similarGroups.isEmpty && !selectedPhotos.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Delete (\(selectedPhotos.count))") {
                            showingDeleteConfirmation = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .confirmationDialog(
                "Delete \(selectedPhotos.count) photos?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteSelectedPhotos()
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var scanningView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Finding similar photos...")
                .font(.headline)
            ProgressView(value: duplicateDetector.scanProgress)
                .padding(.horizontal, 40)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("No Similar Photos Found")
                .font(.title2)
                .fontWeight(.bold)

            Text("We couldn't find groups of similar photos.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var similarPhotosList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                summaryCard

                ForEach(duplicateDetector.similarGroups) { group in
                    SimilarGroupCard(
                        group: group,
                        selectedPhotos: $selectedPhotos,
                        isPremium: storeManager.isPremium,
                        onUpgradeRequest: { showingPaywall = true }
                    )
                }
            }
            .padding()
        }
    }

    private var summaryCard: some View {
        HStack {
            Image(systemName: "square.on.square")
                .font(.title2)
                .foregroundStyle(.purple)

            VStack(alignment: .leading) {
                Text("\(duplicateDetector.similarGroups.count) groups found")
                    .font(.headline)
                Text("Photos taken around the same time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func deleteSelectedPhotos() async {
        let photosToDelete = photoManager.allPhotos.filter { selectedPhotos.contains($0.id) }
        try? await photoManager.deleteAssets(photosToDelete)
        selectedPhotos.removeAll()
        await duplicateDetector.scanForSimilarPhotos(photos: photoManager.allPhotos)
    }
}

struct SimilarGroupCard: View {
    let group: SimilarPhotosGroup
    @Binding var selectedPhotos: Set<String>
    let isPremium: Bool
    let onUpgradeRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let date = group.dateTaken {
                    Text(date.formattedDate)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                Text("\(group.photos.count) photos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            PhotoGridView(
                photos: group.photos,
                selectedPhotos: $selectedPhotos,
                isPremium: isPremium,
                onUpgradeRequest: onUpgradeRequest
            )

            HStack {
                Button {
                    if isPremium {
                        keepBestPhoto()
                    } else {
                        onUpgradeRequest()
                    }
                } label: {
                    Label("Keep Best", systemImage: "star.fill")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }

                Spacer()

                Text(totalSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var totalSize: String {
        let total = group.photos.reduce(0) { $0 + $1.fileSize }
        return total.formattedFileSize
    }

    private func keepBestPhoto() {
        let sorted = group.photos.sorted { $0.fileSize > $1.fileSize }
        for photo in sorted.dropFirst() {
            selectedPhotos.insert(photo.id)
        }
    }
}

#Preview {
    SimilarPhotosView()
        .environmentObject(StoreManager())
}
