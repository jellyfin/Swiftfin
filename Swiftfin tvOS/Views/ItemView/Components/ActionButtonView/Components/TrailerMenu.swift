//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct TrailerMenu: View {

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        @ObservedObject
        var viewModel: ItemViewModel

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @State
        private var error: Error?

        // MARK: - Body

        var body: some View {
            ActionButton(L10n.trailers, icon: "movieclapper") {
                if viewModel.localTrailers.isNotEmpty {
                    Section(L10n.local) {
                        ForEach(viewModel.localTrailers, id: \.self) { trailer in
                            Button {
                                if let selectedMediaSource = trailer.mediaSources?.first {
                                    router.route(
                                        to: \.videoPlayer,
                                        OnlineVideoPlayerManager(item: trailer, mediaSource: selectedMediaSource)
                                    )
                                } else {
                                    error = JellyfinAPIError("No media sources found")
                                }
                            } label: {
                                HStack {
                                    Text(trailer.name ?? L10n.trailer)
                                    Spacer()
                                    Image(systemName: "play")
                                }
                                .font(.body.weight(.bold))
                            }
                        }
                    }
                }

                if let externaltrailers = viewModel.item.remoteTrailers {
                    Section(L10n.external) {
                        ForEach(externaltrailers, id: \.url) { trailer in
                            Button {
                                if let url = trailer.url, let nsUrl = URL(string: url.description) {
                                    if UIApplication.shared.canOpenURL(nsUrl) {
                                        UIApplication.shared.open(nsUrl, options: [:], completionHandler: { success in
                                            if !success {
                                                self.error = JellyfinAPIError(
                                                    """
                                                    Failed to open this trailer. Please ensure that you have the appropriate app to play this trailer installed on your device.

                                                    \(url)
                                                    """
                                                )
                                            }
                                        })
                                    } else {
                                        self.error = JellyfinAPIError(
                                            """
                                            Unable to open this trailer.

                                            \(url)
                                            """
                                        )
                                    }
                                } else {
                                    error = JellyfinAPIError("This trailer does not have a valid URL.")
                                }
                            } label: {
                                HStack {
                                    Text(trailer.name ?? L10n.trailer)
                                    Spacer()
                                    Image(systemName: "arrow.up.forward")
                                }
                                .font(.body.weight(.bold))
                            }
                        }
                    }
                }
            }
            .errorMessage($error)
        }
    }
}
