//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import Logging
import SwiftUI

extension ItemView {

    struct TrailerMenu: View {

        private let logger = Logger.swiftfin()

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @FocusState
        private var isFocused: Bool

        @Router
        private var router

        @State
        private var error: Error?

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

        // MARK: Play Local Trailer

        private func playLocalTrailer(_ trailer: BaseItemDto) {
            guard let selectedMediaSource = trailer.mediaSources?.first else {
                logger.log(level: .error, "No media sources found")
                error = ErrorMessage(L10n.unknownError)
                return
            }

            let manager = MediaPlayerManager(item: trailer) { item in
                try await MediaPlayerItem.build(for: item, mediaSource: selectedMediaSource)
            }

            router.route(to: .videoPlayer(manager: manager))
        }

        // MARK: Play External Trailer

        private func playExternalTrailer(_ trailer: MediaURL) {
            guard let urlString = trailer.url else {
                error = ErrorMessage(L10n.unableToOpenTrailer)
                return
            }

            guard let externalURL = ExternalTrailerURL(string: urlString) else {
                error = ErrorMessage(L10n.unableToOpenTrailer)
                return
            }

            if externalURL.canBeOpened {
                UIApplication.shared.open(externalURL.deepLink) { success in
                    if !success {
                        error = ErrorMessage(L10n.unableToOpenTrailerApp(externalURL.source.displayTitle))
                    }
                }
            } else {
                error = ErrorMessage(L10n.unableToOpenTrailer)
            }
        }
    }
}
