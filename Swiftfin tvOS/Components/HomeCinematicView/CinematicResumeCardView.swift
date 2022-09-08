//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CinematicResumeCardView: View {

    @EnvironmentObject
    private var homeRouter: HomeCoordinator.Router
    @ObservedObject
    var viewModel: HomeViewModel
    let item: BaseItemDto

    var body: some View {
        VStack(alignment: .leading) {
            Button {
                homeRouter.route(to: \.item, item)
            } label: {
                ZStack(alignment: .bottom) {

                    if item.type == .episode {
                        ImageView([
                            item.seriesImageSource(.thumb, maxWidth: 350),
                            item.seriesImageSource(.backdrop, maxWidth: 350),
                        ])
                        .frame(width: 350, height: 210)
                    } else {
                        ImageView([
                            item.imageSource(.thumb, maxWidth: 350),
                            item.imageSource(.backdrop, maxWidth: 350),
                        ])
                        .frame(width: 350, height: 210)
                    }

                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 105)
                    .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.progress ?? "")
                            .font(.subheadline)
                            .padding(.vertical, 5)
                            .padding(.leading, 10)
                            .foregroundColor(.white)

                        HStack {
                            Color.jellyfinPurple
                                .frame(width: 350 * (item.userData?.playedPercentage ?? 0) / 100, height: 7)

                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(width: 350, height: 210)
            }
            .buttonStyle(.card)
            .padding(.top)
            .contextMenu {
                Button(role: .destructive) {
                    viewModel.removeItemFromResume(item)
                } label: {
                    L10n.removeFromResume.text
                }
            }
        }
        .padding(.vertical)
    }
}
