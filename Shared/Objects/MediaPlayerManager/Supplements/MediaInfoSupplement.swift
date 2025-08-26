//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: scroll if description too long

struct MediaInfoSupplement: MediaPlayerSupplement {

    let displayTitle: String = "Info"
    let id: String = "MediaInfoSupplement"
    let item: BaseItemDto

    var videoPlayerBody: some PlatformView {
        _View(item: item)
    }
}

extension MediaInfoSupplement {

    private struct _View: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        let item: BaseItemDto

        @ViewBuilder
        private var accessoryView: some View {
            DotHStack {
                if item.type == .episode, let seasonEpisodeLocator = item.seasonEpisodeLabel {
                    Text(seasonEpisodeLocator)
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

        @ViewBuilder
        private var fromBeginningButton: some View {
            Button("From Beginning", systemImage: "play.fill") {
                manager.proxy?.setSeconds(.zero)
                manager.proxy?.play()
                containerState.selectedSupplement = nil
            }
            #if os(iOS)
            .buttonStyle(.material)
            #endif
            .frame(width: 200, height: 50)
            .font(.subheadline)
            .fontWeight(.semibold)
        }

        // TODO: may need to be a layout for correct overview frame
        //       with scrolling if too long
        var iOSView: some View {
            let shouldBeCompact: (CGSize) -> Bool = { size in
                size.width < 300 || size.isPortrait
            }

            CompactOrRegularView(shouldBeCompact: shouldBeCompact) {
                iOSCompactView
            } regularView: {
                iOSRegularView
            }
            .padding(.leading, safeAreaInsets.leading)
            .padding(.trailing, safeAreaInsets.trailing)
            .edgePadding(.horizontal)
        }

        @ViewBuilder
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
                }
                .allowsHitTesting(false)

                accessoryView
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }

        @ViewBuilder
        private var iOSRegularView: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                AlternateLayoutView {
                    Color.clear
                } content: {
                    ImageView(item.portraitImageSources(maxWidth: 60))
                        .failure {
                            SystemImageContentView(systemName: item.systemImage)
                        }
                }
                .posterStyle(.portrait, contentMode: .fit)
                .posterShadow()

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
                        fromBeginningButton
                    }
                }
            }
        }

        var tvOSView: some View { EmptyView() }
    }
}

struct MediaInfoSupplement_Previews: PreviewProvider {
    static var previews: some View {
        MediaInfoSupplement(item: .init(
            indexNumber: 1,
            name: "The Bear",
            overview: "A young chef returns home to Chicago to run his family's sandwich shop after his brother's death.",
            parentIndexNumber: 1,
            runTimeTicks: 10_000_000_000,
            type: .episode
        ))
        .videoPlayerBody
        .eraseToAnyView()
        .environment(\.horizontalSizeClass, .regular)
        .previewInterfaceOrientation(.landscapeLeft)
        .frame(height: 150)
    }
}
