//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

extension ItemVideoPlayer.Overlay {

    struct TopBarView: View {

        @EnvironmentObject
        private var router: ItemVideoPlayerCoordinator.Router

        @ObservedObject
        var viewModel: ItemVideoPlayerViewModel

        var body: some View {
            VStack(alignment: .EpisodeSeriesAlignmentGuide) {
                HStack(alignment: .center) {
                    Button {
                        viewModel.eventSubject.send(.cancel)
                        router.dismissCoordinator()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .padding()
                            .padding(.trailing, -10)
                    }

                    Text(viewModel.item.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
                            context[.leading]
                        }

                    Spacer()

                    ItemVideoPlayer.Overlay.ActionButtons(viewModel: viewModel)
                        .padding(.leading, 100)
                }
                .font(.system(size: 24))
                .tint(Color.white)
                .foregroundColor(Color.white)

                if let subtitle = viewModel.item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                        .alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
                            context[.leading]
                        }
                        .offset(y: -18)
                }
            }
        }
    }
}
