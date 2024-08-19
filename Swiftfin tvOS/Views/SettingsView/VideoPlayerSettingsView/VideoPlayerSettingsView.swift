//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct VideoPlayerSettingsView: View {
    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    @EnvironmentObject
    private var router: VideoPlayerSettingsCoordinator.Router

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "tv")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                switch videoPlayerType {
                case .native:
                    ResumeOffsetSection()

                case .swiftfin:
                    // Not currently available for tvOS
                    PlayerControlsSection()

                    ResumeOffsetSection()
                    // Not currently available for tvOS
                    ButtonSection()
                    // Not currently available for tvOS
                    SliderSection()

                    SubtitleSection()
                    // Not currently available for tvOS
                    TimestampSection()

                    TransitionSection()
                }
            }
            .navigationTitle(L10n.videoPlayer.text)
    }
}
