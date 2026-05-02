//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: scroll if description too long

struct MediaInfoSupplement: MediaPlayerSupplement {

    let displayTitle: String = L10n.info
    let item: BaseItemDto

    var id: String {
        "MediaInfo-\(item.id ?? "any")"
    }

    var videoPlayerBody: some PlatformView {
        InfoOverlay(item: item)
    }
}

extension MediaInfoSupplement {

    private struct InfoOverlay: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @FocusState
        private var isResetButtonFocused: Bool

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        let item: BaseItemDto

        @ViewBuilder
        private var accessoryView: some View {
            VStack(alignment: .leading) {
                DotHStack {
                    if item.type == .episode {
                        if let premiereDateLabel = item.premiereDateLabel {
                            Text(premiereDateLabel)
                        }
                        if let seasonEpisodeLocator = item.seasonEpisodeLabel {
                            Text(seasonEpisodeLocator)
                        }
                    } else if let premiereYear = item.premiereDateYear {
                        Text(premiereYear)
                    }
                    if let runtime = item.runTimeLabel {
                        Text(runtime)
                    }
                    if let officialRating = item.officialRating {
                        Text(officialRating)
                    }
                }
            }
        }

        private var resetPlaybackButton: some View {
            Button {
                manager.proxy?.setSeconds(.zero)
                manager.setPlaybackRequestStatus(status: .playing)
                containerState.select(supplement: nil)
            } label: {
                Label(L10n.fromBeginning, systemImage: "play.fill")
                    .padding()
            }
            .buttonStyle(.material)
            .font(.subheadline.weight(.semibold))
        }

        // TODO: may need to be a layout for correct overview frame
        //       with scrolling if too long
        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                iOSCompactView
            } regularView: {
                regularView
            }
            .padding(.leading, safeAreaInsets.leading)
            .padding(.trailing, safeAreaInsets.trailing)
        }

        @ViewBuilder
        private var iOSCompactView: some View {
            VStack(alignment: .leading) {
                Text(item.displayTitle)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let overview = item.overview {
                    Text(overview)
                        .font(.subheadline)
                        .fontWeight(.regular)
                }

                accessoryView
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !item.isLiveStream {
                    resetPlaybackButton
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .padding(.vertical)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .edgePadding()
        }

        @ViewBuilder
        private var regularView: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                // TODO: determine what to do with non-portrait (channel, home video) images
                //       - use aspect ratio?
                PosterImage(
                    item: item,
                    type: item.preferredPosterDisplayType,
                    contentMode: .fit
                )
                .posterCornerRadius(item.preferredPosterDisplayType)
                .environment(\.isOverComplexContent, true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(.callout.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let overview = item.overview {
                        Text(overview)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .lineLimit(4)
                    }

                    accessoryView
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !item.isLiveStream {
                    AlternateLayoutView {
                        Label(L10n.fromBeginning, systemImage: "play.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(safeAreaInsets)
                            .frame(height: UIDevice.isTV ? 75 : 50)
                    } content: {
                        resetPlaybackButton
                            .focusSection()
                    }
                }
            }
            .edgePadding()
        }

        var tvOSView: some View {
            regularView
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
