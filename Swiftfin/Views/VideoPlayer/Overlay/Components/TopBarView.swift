//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import Stinsen
import SwiftUI
import VLCUI

extension ItemVideoPlayer.Overlay {

    struct TopBarView: View {

        @EnvironmentObject
        private var router: ItemVideoPlayerCoordinator.Router
        @EnvironmentObject
        private var viewModel: ItemVideoPlayerViewModel
        @State
        private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

        init() {
            print("Top bar init-ed")
        }

        var body: some View {
            HStack(alignment: .center) {
                Button {
                    viewModel.proxy.stop()
                    router.dismissCoordinator()
                } label: {
                    Image(systemName: "xmark")
                        .padding()
                }

                VStack {
                    Text(viewModel.item.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(1)

                    if let subtitle = viewModel.item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(Color.gray)
                            .alignmentGuide(.EpisodeSeriesAlignmentGuide) { context in
                                context[.leading]
                            }
                    }
                }

                Spacer()

                ItemVideoPlayer.Overlay.ActionButtons()
                    .if(deviceOrientation.isLandscape) { view in
                        view.padding(.leading, 100)
                    }
            }
            .font(.system(size: 24))
            .tint(Color.white)
            .foregroundColor(Color.white)
            .detectOrientation($deviceOrientation)
        }
    }
}
