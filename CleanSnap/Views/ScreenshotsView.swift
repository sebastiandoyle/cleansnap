import SwiftUI

struct ScreenshotsView: View {
    @StateObject private var photoManager = PhotoManager.shared
    @EnvironmentObject var storeManager: StoreManager
    @State private var selectedPhotos: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingPaywall = false
    @State private var sortOrder: SortOrder = .newest

    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case largest = "Largest"
    }

    var sortedScreenshots: [PhotoAsset] {
        switch sortOrder {
        case .newest:
            return photoManager.screenshots.sorted { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        case .oldest:
            return photoManager.screenshots.sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        case .largest:
            return photoManager.screenshots.sorted { $0.fileSize > $1.fileSize }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if photoManager.screenshots.isEmpty {
                    emptyStateView
                } else {
                    screenshotsList
                }
            }
            .navigationTitle("Screenshots")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrder = order
                            } label: {
                                Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }

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
                "Delete \(selectedPhotos.count) screenshots?",
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
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("No Screenshots")
                .font(.title2)
                .fontWeight(.bold)

            Text("You don't have any screenshots in your library.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var screenshotsList: some View {
        VStack(spacing: 0) {
            summaryCard
                .padding()

            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 4) {
                    ForEach(sortedScreenshots) { screenshot in
                        ScreenshotThumbnail(
                            photo: screenshot,
                            isSelected: selectedPhotos.contains(screenshot.id),
                            onTap: {
                                if storeManager.isPremium {
                                    toggleSelection(screenshot.id)
                                } else {
                                    showingPaywall = true
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var summaryCard: some View {
        HStack {
            Image(systemName: "camera.viewfinder")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading) {
                Text("\(photoManager.screenshots.count) screenshots")
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
        let total = photoManager.screenshots.reduce(0) { $0 + $1.fileSize }
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
        for screenshot in photoManager.screenshots {
            selectedPhotos.insert(screenshot.id)
        }
    }

    private func deleteSelectedPhotos() async {
        let photosToDelete = photoManager.screenshots.filter { selectedPhotos.contains($0.id) }
        try? await photoManager.deleteAssets(photosToDelete)
        selectedPhotos.removeAll()
    }
}

struct ScreenshotThumbnail: View {
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
            .frame(minHeight: 150)
            .clipped()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white, .blue)
                    .padding(8)
            }
        }
        .overlay(
            Rectangle()
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .onTapGesture(perform: onTap)
        .task {
            thumbnail = await PhotoManager.shared.loadThumbnail(
                for: photo.asset,
                targetSize: CGSize(width: 300, height: 400)
            )
        }
    }
}

#Preview {
    ScreenshotsView()
        .environmentObject(StoreManager())
}
