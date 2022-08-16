//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ContinueWatchingView: View {

    @EnvironmentObject
    private var homeRouter: HomeCoordinator.Router
    @ObservedObject
    var viewModel: HomeViewModel

    var body: some View {
        PosterHStack(title: "", type: .landscape, items: viewModel.resumeItems)
            .scaleItems(1.5)
            .onSelect { item in
                homeRouter.route(to: \.item, item)
            }
            .contextMenu { item in
                Button(role: .destructive) {
                    viewModel.removeItemFromResume(item)
                } label: {
                    Label(L10n.removeFromResume, systemImage: "minus.circle")
                }
            }
            .imageOverlay { item in
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
}
