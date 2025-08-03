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
// TODO: other buttons depending on item type

struct MediaInfoSupplement: MediaPlayerSupplement {

    let displayTitle: String = "Info"
    let id: String = "MediaInfoSupplement"
    let item: BaseItemDto

    func videoPlayerBody() -> some View {
        _View(item: item)
    }
}

extension MediaInfoSupplement {

    private struct _View: View {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets
        @Environment(\.selectedMediaPlayerSupplement)
        @Binding
        private var selectedMediaPlayerSupplement: AnyMediaPlayerSupplement?

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
                selectedMediaPlayerSupplement = nil
            }
//            .buttonStyle(.videoPlayerDrawerContent)
            .frame(width: 275, height: 50)
        }

//        var compact: some View {
//            VStack(alignment: .leading) {
//                Text(item.displayTitle)
//                    .fontWeight(.semibold)
//                    .lineLimit(2)
//                    .multilineTextAlignment(.leading)
//
//                if let overview = item.overview {
//                    Text(overview)
//                        .font(.subheadline)
//                        .fontWeight(.regular)
//                }
//
//                accessoryView
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//            }
//            .frame(maxWidth: .infinity, alignment: .topLeading)
//        }

        // TODO: may need to be a layout for correct overview frame
        //       with scrolling if too long
        var body: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                ImageView(item.portraitImageSources(maxWidth: 60))
                    .failure {
                        SystemImageContentView(systemName: item.systemImage)
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

                VStack {
                    fromBeginningButton
                }
            }
            .padding(.leading, safeAreaInsets.leading)
            .padding(.trailing, safeAreaInsets.trailing)
        }
    }
}

#Preview {
    MediaInfoSupplement(item: .init(
        indexNumber: 1,
        name: "The Bear",
        overview: "A young chef returns home to Chicago to run his family's sandwich shop after his brother's death.",
        parentIndexNumber: 1,
        runTimeTicks: 10_000_000_000,
        type: .episode
    ))
    .videoPlayerBody()
    .eraseToAnyView()
    .padding(EdgeInsets.edgePadding)
    .environment(\.horizontalSizeClass, .regular)
    .previewInterfaceOrientation(.landscapeLeft)
    .frame(height: 150)
}
