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

    let title: String = "Info"
    let item: BaseItemDto

    var id: String {
        "MediaInfoSupplement"
    }

    func videoPlayerBody() -> some View {
        _View(item: item)
    }

    private struct _View: View {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @Environment(\.selectedMediaPlayerSupplement)
        @Binding
        private var selectedMediaPlayerSupplement: AnyMediaPlayerSupplement?

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var contentSize: CGSize = .zero

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
                manager.proxy?.setTime(0)
                manager.set(seconds: 0)
                selectedMediaPlayerSupplement = nil
            }
//            .buttonStyle(.videoPlayerDrawerContent)
            .frame(width: 275, height: 50)
        }

        var body: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                ZStack {
                    Color.clear

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
                            .font(.subheadline.weight(.regular))
                            .scrollIfLargerThanContainer()
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
            .padding(.horizontal, safeAreaInsets.leading)
            .trackingSize($contentSize)
        }
    }
}

// struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        MediaInfoSupplement(item: .init(
//            indexNumber: 1,
//            name: "The Bear",
//            parentIndexNumber: 1,
//            runTimeTicks: 10_000_000_000,
//            type: .episode
//        ))
//        .videoPlayerBody()
//        .eraseToAnyView()
//        .environment(\.safeAreaInsets, .constant(EdgeInsets.edgeInsets))
//        .frame(height: 110)
//        .previewInterfaceOrientation(.landscapeRight)
//    }
// }
