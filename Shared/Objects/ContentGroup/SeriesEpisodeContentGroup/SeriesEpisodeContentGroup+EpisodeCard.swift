//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension SeriesEpisodeContentGroup {

    struct EpisodeCard: View {

        @Environment(\.enabledPosterIndicators)
        private var indicators

        @Namespace
        private var namespace

        @Router
        private var router

        let episode: BaseItemDto

        @ViewBuilder
        private var overlayView: some View {
            if indicators.contains(.progress), let progressLabel = episode.progressLabel {
                ProgressIndicator(
                    title: progressLabel,
                    progress: (episode.userData?.playedPercentage ?? 0) / 100,
                    posterDisplayType: .landscape
                )
            } else if indicators.contains(.played), episode.userData?.isPlayed ?? false {
                PlayedIndicator()
                    .frame(width: UIDevice.isTV ? 45 : 25, height: UIDevice.isTV ? 45 : 25)
                    .padding(3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }

        private var episodeContent: String {
            if episode.isUnaired {
                episode.airDateLabel ?? L10n.noOverviewAvailable
            } else {
                episode.overview ?? L10n.noOverviewAvailable
            }
        }

        var body: some View {
            EpisodeCardLayout(
                header: episode.displayTitle,
                subHeader: episode.episodeLocator ?? .emptyDash,
                content: episodeContent,
                artworkAction: {
                    router.route(
                        to: .videoPlayer(
                            item: episode,
                            queue: EpisodeMediaPlayerQueue(episode: episode)
                        )
                    )
                },
                contentAction: {
                    router.route(to: .item(item: episode), in: namespace)
                }
            ) {
                ImageView(episode.landscapeImageSources(
                    environment: .init(
                        maxWidth: 250,
                        useParent: false
                    )
                ))
                .failure {
                    SystemImageContentView(systemName: episode.systemImage)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    overlayView
                }
                .contentShape(.contextMenuPreview, Rectangle())
                .posterStyle(.landscape)
                .posterShadow()
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
            }
        }
    }

    struct EpisodeStateCard: View {

        let title: String
        let subHeader: String
        let content: String
        let systemImage: String?
        let action: () -> Void

        var body: some View {
            EpisodeCardLayout(
                header: title,
                subHeader: subHeader,
                content: content,
                artworkAction: action,
                contentAction: action
            ) {
                Rectangle()
                    .fill(.complexSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        if let systemImage {
                            RelativeSystemImageView(systemName: systemImage)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .posterStyle(.landscape)
                    .posterShadow()
            }
        }
    }

    private struct EpisodeCardLayout<Artwork: View>: View {

        private enum FocusedElement: Hashable {
            case artwork
            case content
        }

        @FocusState
        private var focusedElement: FocusedElement?

        let header: String
        let subHeader: String
        let content: String
        let artworkAction: () -> Void
        let contentAction: () -> Void
        let artwork: Artwork

        init(
            header: String,
            subHeader: String,
            content: String,
            artworkAction: @escaping () -> Void,
            contentAction: @escaping () -> Void,
            @ViewBuilder artwork: () -> Artwork
        ) {
            self.header = header
            self.subHeader = subHeader
            self.content = content
            self.artworkAction = artworkAction
            self.contentAction = contentAction
            self.artwork = artwork()
        }

        var body: some View {
            VStack(alignment: .leading) {
                Button(action: artworkAction) {
                    artwork
                }
                .buttonStyle(.card)
                .focused($focusedElement, equals: .artwork)

                Button(action: contentAction) {
                    EpisodeMetadataView(
                        header: header,
                        subHeader: subHeader,
                        content: content
                    )
                }
                #if os(tvOS)
                .buttonStyle(
                    EpisodeContentButtonStyle(
                        showsMaterial: focusedElement != nil,
                        isFocused: focusedElement == .content
                    )
                )
                #else
                .buttonStyle(.plain)
                #endif
                .focused($focusedElement, equals: .content)
            }
            .focusSection()
            .backport
            .defaultFocus(
                $focusedElement,
                .artwork,
                priority: .userInitiated
            )
        }
    }

    private struct EpisodeMetadataView: View {

        let header: String
        let subHeader: String
        let content: String

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(subHeader)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(header)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                SeeMoreText(content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3, reservesSpace: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    #if os(tvOS)
    private struct EpisodeContentButtonStyle: ButtonStyle {

        let showsMaterial: Bool
        let isFocused: Bool

        private let cornerRadius: CGFloat = 20

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(28)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .frame(height: 200)
                .backport
                .glassEffect(
                    showsMaterial ? .regular : .identity,
                    in: .rect(
                        cornerRadius: cornerRadius,
                        style: .continuous
                    )
                )
                .scaleEffect(isFocused ? 1.05 : 1)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .brightness(isFocused ? 0.04 : 0)
                .opacity(configuration.isPressed ? 0.85 : 1)
                .shadow(
                    color: .black.opacity(isFocused ? 0.3 : 0),
                    radius: isFocused ? 18 : 0,
                    y: isFocused ? 10 : 0
                )
                .animation(.easeInOut(duration: 0.2), value: showsMaterial)
                .animation(.easeOut(duration: 0.15), value: isFocused)
                .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    #endif
}
