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
        var viewModel: MediaViewModel

        @Namespace
        private var namespace

        @State
        private var imageSources: [ImageSource] = []

        let type: MediaViewModel.MediaType
        let action: (Namespace.ID) -> Void

        private var useTitleLabel: Bool {
            useRandomImage ||
                type == .downloads ||
                type == .favorites ||
                type == .watchlist
        }

        private func setImageSources() {
            Task { @MainActor in
                #if os(tvOS)
                // tvOS: every tile shows a random BACKDROP of its category's content (clean art, no
                // baked-in titles). Live TV has no "random" items, so it uses its own backdrop.
                if case let MediaViewModel.MediaType.liveTV(item) = type {
                    // Prefer a backdrop, fall back to the Live TV view's primary; if neither exists the
                    // tile renders the styled gradient + icon below.
                    if item.backdropImageTags?.isNotEmpty == true {
                        self.imageSources = [item.imageSource(.backdrop, maxWidth: 800)]
                    } else {
                        self.imageSources = [item.imageSource(.primary, maxWidth: 800)]
                    }
                } else {
                    self.imageSources = await (try? viewModel.randomItemImageSources(for: type)) ?? []
                }
                #else
                if useRandomImage {
                    self.imageSources = try await viewModel.randomItemImageSources(for: type)
                    return
                }

                if case let MediaViewModel.MediaType.collectionFolder(item) = type {
                    self.imageSources = [item.imageSource(.primary, maxWidth: 500)]
                } else if case let MediaViewModel.MediaType.liveTV(item) = type {
                    self.imageSources = [item.imageSource(.primary, maxWidth: 500)]
                }
                #endif
            }
        }

        @ViewBuilder
        private var titleLabel: some View {
            Text(type.displayTitle)
                // tvOS: match the app's section-title spec (PosterHStack uses size 32 semibold) so the
                // tile labels read as part of the same UI. iOS keeps its original `.title2`.
                    .font(UIDevice.isTV ? .system(size: 32, weight: .semibold) : .title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
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

        #if os(tvOS)
        // tvOS: the backdrop comes from the shared view model (resolved + prefetched at launch / on tab
        // exit), so it's already cached when shown — no on-screen fetch/blur-in.
        private var tvImageSources: [ImageSource] {
            guard let id = type.id else { return [] }
            return viewModel.tileImageSources[id] ?? []
        }

        // tvOS: a clean backdrop card with the label UNDERNEATH (never written over the artwork), so
        // the selection focus ring stays around just the image — matching the home poster rows.
        var body: some View {
            VStack(spacing: 12) {
                Button {
                    action(namespace)
                } label: {
                    ImageView(tvImageSources)
                        .placeholder { imageSource in
                            DefaultPlaceholderView(blurHash: imageSource.blurHash)
                        }
                        .failure {
                            // Styled placeholder for tiles without artwork (Live TV, empty
                            // Favorites/Watchlist): a soft gradient with the category icon — reads as
                            // intentional rather than a broken image.
                            ZStack {
                                LinearGradient(
                                    colors: [
                                        Color.secondarySystemFill,
                                        Color.black.opacity(0.55),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                Image(systemName: type.systemImage)
                                    .font(.system(size: 72, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                        .id(tvImageSources.hashValue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .posterStyle(.landscape)
                }
                .buttonStyle(.card)

                Text(type.displayTitle)
                    .font(.system(size: 30, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        #else
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
        #endif
    }
}
