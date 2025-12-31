//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import Logging
import SwiftUI

extension ItemView {

    struct TrailerMenu: View {

        // MARK: - Stored Value

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        // MARK: - Observed & Envirnoment Objects

        @Router
        private var router

        // MARK: - Error State

        @State
        private var error: Error?

        let localTrailers: [BaseItemDto]
        let externalTrailers: [MediaURL]
        private let logger = Logger.swiftfin()

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

        @ViewBuilder
        private var trailerButton: some View {
            Button(
                L10n.trailers,
                systemImage: "movieclapper"
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
            Menu(L10n.trailers, systemImage: "movieclapper") {

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
            if let mediaSource = trailer.mediaSources?.first {
                router.route(to: .videoPlayer(item: trailer, mediaSource: mediaSource))
            } else {
                logger.log(level: .error, "No media sources found")
                error = ErrorMessage(L10n.unknownError)
            }
        }

        // MARK: - Play: External Trailer

        private func playExternalTrailer(_ trailer: MediaURL) {
            if let url = URL(string: trailer.url), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    guard !success else { return }

                    error = ErrorMessage(L10n.unableToOpenTrailer)
                }
            } else {
                error = ErrorMessage(L10n.unableToOpenTrailer)
            }
        }
    }
}
