import SwiftUI

struct DuplicatesView: View {
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
                } else if duplicateDetector.duplicateGroups.isEmpty {
                    emptyStateView
                } else {
                    duplicatesList
                }
            }
            .navigationTitle("Duplicates")
            .toolbar {
                if !duplicateDetector.duplicateGroups.isEmpty && !selectedPhotos.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Delete Selected") {
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
            } message: {
                Text("This will permanently remove the selected photos from your library.")
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

            Text("Scanning for duplicates...")
                .font(.headline)

            ProgressView(value: duplicateDetector.scanProgress)
                .padding(.horizontal, 40)

            Text("\(Int(duplicateDetector.scanProgress * 100))%")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("No Duplicates Found")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your photo library is clean!")
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await duplicateDetector.scanForDuplicates(photos: photoManager.allPhotos)
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

    private var duplicatesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                summaryHeader

                ForEach(duplicateDetector.duplicateGroups) { group in
                    DuplicateGroupCard(
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

    private var summaryHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(duplicateDetector.totalDuplicatesFound) duplicates")
                    .font(.headline)
                Text(duplicateDetector.potentialSpaceSaved.formattedFileSize + " can be saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                selectAllDuplicates()
            } label: {
                Text("Select All")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func selectAllDuplicates() {
        for group in duplicateDetector.duplicateGroups {
            for photo in group.photos.dropFirst() {
                selectedPhotos.insert(photo.id)
            }
        }
    }

    private func deleteSelectedPhotos() async {
        let photosToDelete = photoManager.allPhotos.filter { selectedPhotos.contains($0.id) }
        try? await photoManager.deleteAssets(photosToDelete)
        selectedPhotos.removeAll()
        await duplicateDetector.scanForDuplicates(photos: photoManager.allPhotos)
    }
}

struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    @Binding var selectedPhotos: Set<String>
    let isPremium: Bool
    let onUpgradeRequest: () -> Void
    @State private var showingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(group.photos.count) identical photos")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(group.potentialSavings.formattedFileSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(group.photos) { photo in
                        PhotoThumbnailView(
                            photo: photo,
                            isSelected: selectedPhotos.contains(photo.id),
                            onTap: {
                                if isPremium {
                                    toggleSelection(photo.id)
                                } else {
                                    onUpgradeRequest()
                                }
                            }
                        )
                    }
                }
            }

            HStack {
                Button {
                    if isPremium {
                        keepFirstOnly()
                    } else {
                        onUpgradeRequest()
                    }
                } label: {
                    Text("Keep First")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }

                Button {
                    if isPremium {
                        selectAllInGroup()
                    } else {
                        onUpgradeRequest()
                    }
                } label: {
                    Text("Select All")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func toggleSelection(_ id: String) {
        if selectedPhotos.contains(id) {
            selectedPhotos.remove(id)
        } else {
            selectedPhotos.insert(id)
        }
    }

    private func keepFirstOnly() {
        for photo in group.photos.dropFirst() {
            selectedPhotos.insert(photo.id)
        }
    }

    private func selectAllInGroup() {
        for photo in group.photos {
            selectedPhotos.insert(photo.id)
        }
    }
}

struct PhotoThumbnailView: View {
    let photo: PhotoAsset
    let isSelected: Bool
    let onTap: () -> Void
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .blue)
                    .padding(4)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .onTapGesture(perform: onTap)
        .task {
            thumbnail = await PhotoManager.shared.loadThumbnail(
                for: photo.asset,
                targetSize: CGSize(width: 160, height: 160)
            )
        }
    }
}

#Preview {
    DuplicatesView()
        .environmentObject(StoreManager())
}
