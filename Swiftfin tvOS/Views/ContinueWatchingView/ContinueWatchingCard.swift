//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ContinueWatchingCard: View {

    @EnvironmentObject
    private var homeRouter: HomeCoordinator.Router
    let item: BaseItemDto

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                homeRouter.route(to: \.item, item)
            } label: {
                ZStack(alignment: .bottom) {

                    if item.type == .episode {
                        ImageView([
                            item.seriesImageSource(.thumb, maxWidth: 500),
                            item.imageSource(.primary, maxWidth: 500),
                        ])
                        .frame(width: 500, height: 281.25)
                    } else {
                        ImageView(item.imageURL(.backdrop, maxWidth: 500))
                            .frame(width: 500, height: 281.25)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.progress ?? "")
                            .font(.subheadline)
                            .padding(.vertical, 5)
                            .padding(.leading, 10)
                            .foregroundColor(.white)

                        HStack {
                            Color(UIColor.systemPurple)
                                .frame(width: 500 * (item.userData?.playedPercentage ?? 0) / 100, height: 13)

                            Spacer(minLength: 0)
                        }
                    }
                    .background {
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.5), .black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                }
                .frame(width: 500, height: 281.25)
            }
            .buttonStyle(.card)
            .padding(.top)

            VStack(alignment: .leading) {
                Text("\(item.seriesName ?? item.name ?? "")")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(width: 500, alignment: .leading)

                if item.type == .episode {
                    Text(item.episodeLocator ?? .emptyDash)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("")
                }
            }
        }
        .padding(.vertical)
    }
}
