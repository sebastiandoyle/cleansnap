import SwiftUI

struct HomeView: View {
    @StateObject private var photoManager = PhotoManager.shared
    @StateObject private var duplicateDetector = DuplicateDetector.shared
    @EnvironmentObject var storeManager: StoreManager
    @State private var showingPaywall = false
    @State private var storageInfo: StorageInfo?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    storageCard

                    if photoManager.isLoading || duplicateDetector.isScanning {
                        scanningProgressCard
                    } else {
                        quickActionsGrid
                        cleanupSummaryCard
                    }
                }
                .padding()
            }
            .navigationTitle("CleanSnap")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !storeManager.isPremium {
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Premium", systemImage: "crown.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .task {
                await loadData()
            }
        }
    }

    private var storageCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Storage")
                    .font(.headline)
                Spacer()
                if let info = storageInfo {
                    Text(info.freeSpace.formattedFileSize + " free")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let info = storageInfo {
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))

                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * info.usedPercentage)
                        }
                    }
                    .frame(height: 12)

                    HStack {
                        Label(info.usedSpace.formattedFileSize, systemImage: "internaldrive.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(info.totalSpace.formattedFileSize + " total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var scanningProgressCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text(photoManager.isLoading ? "Analyzing Photos..." : "Finding Duplicates...")
                .font(.headline)

            ProgressView(value: photoManager.isLoading ? photoManager.loadingProgress : duplicateDetector.scanProgress)
                .tint(.blue)

            Text("\(Int((photoManager.isLoading ? photoManager.loadingProgress : duplicateDetector.scanProgress) * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            NavigationLink {
                DuplicatesView()
            } label: {
                QuickActionCard(
                    title: "Duplicates",
                    count: duplicateDetector.totalDuplicatesFound,
                    icon: "doc.on.doc.fill",
                    color: .blue
                )
            }

            NavigationLink {
                SimilarPhotosView()
            } label: {
                QuickActionCard(
                    title: "Similar",
                    count: duplicateDetector.similarGroups.count,
                    icon: "square.on.square",
                    color: .purple
                )
            }

            NavigationLink {
                ScreenshotsView()
            } label: {
                QuickActionCard(
                    title: "Screenshots",
                    count: photoManager.screenshots.count,
                    icon: "camera.viewfinder",
                    color: .orange
                )
            }

            NavigationLink {
                LargeFilesView()
            } label: {
                QuickActionCard(
                    title: "Large Files",
                    count: photoManager.largeFiles.count,
                    icon: "arrow.up.circle.fill",
                    color: .red
                )
            }
        }
    }

    private var cleanupSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Potential Savings")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading) {
                    Text(duplicateDetector.potentialSpaceSaved.formattedFileSize)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("can be freed up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    // Quick clean action
                } label: {
                    Text("Clean")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func loadData() async {
        storageInfo = StorageAnalyzer.shared.getStorageInfo()

        if photoManager.authorizationStatus != .authorized {
            let granted = await photoManager.requestAuthorization()
            if !granted { return }
        }

        await photoManager.loadAllPhotos()
        await duplicateDetector.scanForDuplicates(photos: photoManager.allPhotos)
        await duplicateDetector.scanForSimilarPhotos(photos: photoManager.allPhotos)
    }
}

struct QuickActionCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
        .environmentObject(StoreManager())
}
