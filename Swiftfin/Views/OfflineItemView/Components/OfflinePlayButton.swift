//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

// TODO: fix play from beginning

extension OfflineItemView {

    struct PlayButton: View {

        @Default(.accentColor)
        private var accentColor

        @Injected(LogManager.service)
        private var logger

        @EnvironmentObject
        private var mainRouter: MainCoordinator.Router

        @ObservedObject
        var offlineViewModel: OfflineViewModel

        @ObservedObject
        var viewModel: OfflineItemViewModel

        private var title: String {
            if let seriesViewModel = viewModel as? OfflineSeriesItemViewModel {
                return seriesViewModel.playButtonItem?.seasonEpisodeLabel ?? L10n.play
            } else {
                return viewModel.playButtonItem?.playButtonLabel ?? L10n.play
            }
        }

        var body: some View {
            Button {
                if viewModel.playButtonItem != nil,
                   let downloadTask = offlineViewModel.getDownloadForItem(item: viewModel.playButtonItem!)
                {
                    mainRouter.route(
                        to: \.videoPlayer,
                        DownloadVideoPlayerManager(downloadTask: downloadTask, offlineViewModel: offlineViewModel)
                    )
                } else {
                    logger.error("No media source available")
                }
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondarySystemFill) : accentColor)
                        .cornerRadius(10)

                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))

                        Text(title)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : accentColor.overlayColor)
                }
            }
            .disabled(viewModel.playButtonItem == nil)
        }
    }
}
