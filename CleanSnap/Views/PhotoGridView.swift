import SwiftUI

struct PhotoGridView: View {
    let photos: [PhotoAsset]
    @Binding var selectedPhotos: Set<String>
    let isPremium: Bool
    let onUpgradeRequest: () -> Void

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(photos) { photo in
                GridPhotoThumbnail(
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

    private func toggleSelection(_ id: String) {
        if selectedPhotos.contains(id) {
            selectedPhotos.remove(id)
        } else {
            selectedPhotos.insert(id)
        }
    }
}

struct GridPhotoThumbnail: View {
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
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                }
            }
            .frame(width: 80, height: 80)
            .clipped()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white, .blue)
                    .padding(2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
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

struct FullScreenPhotoView: View {
    let photo: PhotoAsset
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            image = await PhotoManager.shared.loadFullImage(for: photo.asset)
        }
    }
}

#Preview {
    PhotoGridView(
        photos: [],
        selectedPhotos: .constant([]),
        isPremium: true,
        onUpgradeRequest: {}
    )
}
