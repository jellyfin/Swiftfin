//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ContinueWatchingLandscapeButton: View {

    @EnvironmentObject
    private var homeRouter: HomeCoordinator.Router

    let item: BaseItemDto

    var body: some View {
        Button {
            homeRouter.route(to: \.item, item)
        } label: {
            VStack(alignment: .leading) {

                ZStack {
                    Group {
                        if item.type == .episode {
                            ImageView([
                                item.seriesImageSource(.thumb, maxWidth: 320),
                                item.seriesImageSource(.backdrop, maxWidth: 320),
                            ])
                            .frame(width: 320, height: 180)
                        } else {
                            ImageView([
                                item.imageSource(.thumb, maxWidth: 320),
                                item.imageSource(.backdrop, maxWidth: 320),
                            ])
                            .frame(width: 320, height: 180)
                        }
                    }
                    .accessibilityIgnoresInvertColors()

                    HStack {
                        VStack {

                            Spacer()

                            ZStack(alignment: .bottom) {

                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.5), .black.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 35)

                                VStack(alignment: .leading, spacing: 0) {
                                    Text(item.getItemProgressString() ?? L10n.continue)
                                        .font(.subheadline)
                                        .padding(.bottom, 5)
                                        .padding(.leading, 10)
                                        .foregroundColor(.white)

                                    HStack {
                                        Color.jellyfinPurple
                                            .frame(width: 320 * (item.userData?.playedPercentage ?? 0) / 100, height: 7)

                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(width: 320, height: 180)
                .mask(Rectangle().cornerRadius(10))
                .shadow(radius: 4, y: 2)

                VStack(alignment: .leading) {
                    Text("\(item.seriesName ?? item.name ?? "")")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if item.type == .episode {
                        Text(item.seasonEpisodeLocator ?? "")
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
