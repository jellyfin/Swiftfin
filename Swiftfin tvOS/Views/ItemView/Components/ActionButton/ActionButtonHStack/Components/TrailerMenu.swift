//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct TrailerMenu: View {

        @Injected(\.logService)
        private var logger

        // MARK: - Stored Value

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        // MARK: - Observed & Envirnoment Objects

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        // MARK: - Error State

        @State
        private var error: Error?

        // MARK: - Notification State

        @State
        private var selectedRemoteURL: MediaURL?

        let localTrailers: [BaseItemDto]
        let externalTrailers: [MediaURL]

        private var showLocalTrailers: Bool {
            enabledTrailers.contains(.local) && localTrailers.isNotEmpty
        }

        private var showExternalTrailers: Bool {
            enabledTrailers.contains(.external) && externalTrailers.isNotEmpty
        }

        // MARK: - Body

        var body: some View {
            Group {
                switch localTrailers.count + externalTrailers.count {
                case 1:
                    trailerButton
                default:
                    trailerMenu
                }
            }
            .errorMessage($error)
        }

        // MARK: - Single Trailer Button

        private var trailerButton: some View {
            ActionButton(
                L10n.trailers,
                icon: "movieclapper",
                selectedIcon: "movieclapper"
            ) {
                if showLocalTrailers, let firstTrailer = localTrailers.first {
                    playLocalTrailer(firstTrailer)
                }

                if showExternalTrailers, let firstTrailer = externalTrailers.first {
                    playExternalTrailer(firstTrailer)
                }
            }
        }

        // MARK: - Multiple Trailers Menu Button

        @ViewBuilder
        private var trailerMenu: some View {
            ActionButton(L10n.trailers, icon: "movieclapper") {

                if showLocalTrailers {
                    Section(L10n.local) {
                        ForEach(localTrailers) { trailer in
                            Button(
                                trailer.name ?? L10n.trailer,
                                systemImage: "play.fill"
                            ) {
                                playLocalTrailer(trailer)
                            }
                        }
                    }
                }

                if showExternalTrailers {
                    Section(L10n.external) {
                        ForEach(externalTrailers, id: \.self) { mediaURL in
                            Button(
                                mediaURL.name ?? L10n.trailer,
                                systemImage: "arrow.up.forward"
                            ) {
                                playExternalTrailer(mediaURL)
                            }
                        }
                    }
                }
            }
        }

        // MARK: - Play: Local Trailer

        private func playLocalTrailer(_ trailer: BaseItemDto) {
            if let selectedMediaSource = trailer.mediaSources?.first {
                router.route(
                    to: \.videoPlayer,
                    OnlineVideoPlayerManager(item: trailer, mediaSource: selectedMediaSource)
                )
            } else {
                logger.log(level: .error, "No media sources found")
                error = JellyfinAPIError(L10n.unknownError)
            }
        }

        // MARK: - Play: External Trailer

        private func playExternalTrailer(_ trailer: MediaURL) {
            if let url = URL(string: trailer.url), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    guard !success else { return }

                    error = JellyfinAPIError(L10n.unableToOpenTrailer)
                }
            } else {
                error = JellyfinAPIError(L10n.unableToOpenTrailer)
            }
        }
    }
}
