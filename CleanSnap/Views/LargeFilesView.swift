import SwiftUI

struct LargeFilesView: View {
    @StateObject private var photoManager = PhotoManager.shared
    @EnvironmentObject var storeManager: StoreManager
    @State private var selectedPhotos: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingPaywall = false
    @State private var filterType: FilterType = .all

    enum FilterType: String, CaseIterable {
        case all = "All"
        case photos = "Photos"
        case videos = "Videos"
    }

    var filteredFiles: [PhotoAsset] {
        switch filterType {
        case .all:
            return photoManager.largeFiles
        case .photos:
            return photoManager.largeFiles.filter { $0.mediaType == .image }
        case .videos:
            return photoManager.largeFiles.filter { $0.mediaType == .video }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if photoManager.largeFiles.isEmpty {
                    emptyStateView
                } else {
                    filesList
                }
            }
            .navigationTitle("Large Files")
            .toolbar {
                if !selectedPhotos.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Delete (\(selectedPhotos.count))") {
                            showingDeleteConfirmation = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .confirmationDialog(
                "Delete \(selectedPhotos.count) files?",
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

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("No Large Files")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your storage is optimized!")
                .foregroundStyle(.secondary)
        }
    }

    private var filesList: some View {
        VStack(spacing: 0) {
            filterPicker

            ScrollView {
                LazyVStack(spacing: 12) {
                    summaryCard

                    ForEach(filteredFiles) { file in
                        LargeFileRow(
                            file: file,
                            isSelected: selectedPhotos.contains(file.id),
                            onTap: {
                                if storeManager.isPremium {
                                    toggleSelection(file.id)
                                } else {
                                    showingPaywall = true
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filterType) {
            ForEach(FilterType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private var summaryCard: some View {
        HStack {
            Image(systemName: "arrow.up.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)

            VStack(alignment: .leading) {
                Text("\(filteredFiles.count) large files")
                    .font(.headline)
                Text(totalSize + " total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                if storeManager.isPremium {
                    selectAll()
                } else {
                    showingPaywall = true
                }
            } label: {
                Text("Select All")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var totalSize: String {
        let total = filteredFiles.reduce(0) { $0 + $1.fileSize }
        return total.formattedFileSize
    }

    private func toggleSelection(_ id: String) {
        if selectedPhotos.contains(id) {
            selectedPhotos.remove(id)
        } else {
            selectedPhotos.insert(id)
        }
    }

    private func selectAll() {
        for file in filteredFiles {
            selectedPhotos.insert(file.id)
        }
    }

    private func deleteSelectedPhotos() async {
        let photosToDelete = photoManager.largeFiles.filter { selectedPhotos.contains($0.id) }
        try? await photoManager.deleteAssets(photosToDelete)
        selectedPhotos.removeAll()
    }
}

struct LargeFileRow: View {
    let file: PhotoAsset
    let isSelected: Bool
    let onTap: () -> Void
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: file.mediaType == .video ? "video.fill" : "photo.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(file.fileSize.formattedFileSize)
                        .font(.headline)
                }

                Text("\(file.pixelWidth) x \(file.pixelHeight)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let date = file.creationDate {
                    Text(date.relativeDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isSelected ? .blue : .gray)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture(perform: onTap)
        .task {
            thumbnail = await PhotoManager.shared.loadThumbnail(
                for: file.asset,
                targetSize: CGSize(width: 120, height: 120)
            )
        }
    }
}

#Preview {
    LargeFilesView()
        .environmentObject(StoreManager())
}
