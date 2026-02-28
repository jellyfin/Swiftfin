//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// Note: the design reason to not have a local label always on top
//       is to have the same failure/empty color for all views

extension MediaView {

    // TODO: custom view for folders and tv (allow customization?)
    //       - differentiate between what media types are Swiftfin only
    //         which would allow some cleanup
    //       - allow server or random view per library?
    // TODO: if local label on image, also needs to be in blurhash placeholder
    struct MediaItem: View {

        @Default(.Customization.Library.randomImage)
        private var useRandomImage

        @ObservedObject
        private var viewModel: MediaViewModel

        @Namespace
        private var namespace

        @State
        private var imageSources: [ImageSource] = []

        private let action: (Namespace.ID) -> Void
        private let mediaType: MediaViewModel.MediaType

        init(
            viewModel: MediaViewModel,
            type: MediaViewModel.MediaType,
            action: @escaping (Namespace.ID) -> Void
        ) {
            self.viewModel = viewModel
            self.action = action
            self.mediaType = type
        }

        private var useTitleLabel: Bool {
            useRandomImage ||
                mediaType == .downloads ||
                mediaType == .favorites
        }

        private func setImageSources() {
            Task { @MainActor in
                if useRandomImage {
                    self.imageSources = try await viewModel.randomItemImageSources(for: mediaType)
                    return
                }

                if case let MediaViewModel.MediaType.collectionFolder(item) = mediaType {
                    self.imageSources = [item.imageSource(.primary, maxWidth: 500)]
                } else if case let MediaViewModel.MediaType.liveTV(item) = mediaType {
                    self.imageSources = [item.imageSource(.primary, maxWidth: 500)]
                }
            }
        }

        @ViewBuilder
        private var titleLabel: some View {
            Text(mediaType.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(alignment: .center)
        }

        private func titleLabelOverlay(with content: some View) -> some View {
            ZStack {
                content

                Color.black
                    .opacity(0.5)

                titleLabel
                    .foregroundStyle(.white)
            }
        }

        var body: some View {
            Button {
                action(namespace)
            } label: {
                ImageView(imageSources)
                    .image { image in
                        if useTitleLabel {
                            titleLabelOverlay(with: image)
                        } else {
                            image
                        }
                    }
                    .placeholder { imageSource in
                        titleLabelOverlay(with: DefaultPlaceholderView(blurHash: imageSource.blurHash))
                    }
                    .failure {
                        Color.secondarySystemFill
                            .opacity(0.75)
                            .overlay {
                                titleLabel
                                    .foregroundColor(.primary)
                            }
                    }
                    .id(imageSources.hashValue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .posterStyle(.landscape)
                    .backport
                    .matchedTransitionSource(id: "item", in: namespace)
            }
            .onFirstAppear(perform: setImageSources)
            .backport
            .onChange(of: useRandomImage) { _, _ in
                setImageSources()
            }
            .buttonStyle(.card)
        }
    }
}
