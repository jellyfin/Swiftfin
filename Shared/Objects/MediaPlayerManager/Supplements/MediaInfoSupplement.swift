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

    let displayTitle: String = "Info"
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

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        #if os(tvOS)
        @EnvironmentObject
        private var focusGuide: FocusGuide

        @FocusState
        private var isResetButtonFocused: Bool
        #endif

        let item: BaseItemDto

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

        private func resetPlayback() {
            manager.proxy?.setSeconds(.zero)
            manager.setPlaybackRequestStatus(status: .playing)
            containerState.select(supplement: nil)
        }

        // TODO: Localize
        private var resetPlaybackButton: some View {
            AlternateLayoutView {
                Button(action: resetPlayback) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .foregroundStyle(.white)

                        Label("From Beginning", systemImage: "play.fill")
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                    }
                }
            } content: {
                Button(action: resetPlayback) {
                    Label("From Beginning", systemImage: "play.fill")
                        .padding()
                }
                .buttonStyle(.material)
                .font(.subheadline)
                .fontWeight(.semibold)
            }
        }

        // TODO: may need to be a layout for correct overview frame
        //       with scrolling if too long
        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                iOSCompactView
            } regularView: {
                iOSRegularView
            }
            .padding(.leading, safeAreaInsets.leading)
            .padding(.trailing, safeAreaInsets.trailing)
            .edgePadding(.horizontal)
            .edgePadding(.bottom)
        }

        private var iOSCompactView: some View {
            VStack(alignment: .leading) {
                Group {
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
                }
                .allowsHitTesting(false)

                if !item.isLiveStream {
                    resetPlaybackButton
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }

        private var iOSRegularView: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                // TODO: determine what to do with non-portrait (channel, home video) images
                //       - use aspect ratio?
                PosterImage(
                    item: item,
                    type: item.preferredPosterDisplayType,
                    contentMode: .fit
                )
                .environment(\.isOverComplexContent, true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let overview = item.overview {
                        Text(overview)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .lineLimit(3)
                    }

                    accessoryView
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !item.isLiveStream {
                    VStack {
                        resetPlaybackButton
                            .frame(width: 200, height: 50)
                    }
                }
            }
        }

        var tvOSView: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                // TODO: determine what to do with non-portrait (channel, home video) images
                //       - use aspect ratio?
                PosterImage(
                    item: item,
                    type: item.preferredPosterDisplayType,
                    contentMode: .fit
                )
                .environment(\.isOverComplexContent, true)

                VStack(alignment: .leading, spacing: 8) {
                    Marquee(item.displayTitle, speed: 120, delay: 3, fade: 5)
                        .font(.title)
                        .fontWeight(.semibold)

                    accessoryView
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let overview = item.overview {
                        Text(overview)
                            .font(.body)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !item.isLiveStream {
                    resetPlaybackButton
                        .frame(height: 75)
                        .fixedSize(horizontal: true, vertical: false)
                    #if os(tvOS)
                        .focused($isResetButtonFocused)
                    #endif
                }
            }
            .padding(safeAreaInsets)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            #if os(tvOS)
                .focusSection()
                .onChange(of: focusGuide.focusedTag) { _, newTag in
                    if newTag == "supplementContent" {
                        isResetButtonFocused = true
                    }
                }
            #endif
        }
    }
}
