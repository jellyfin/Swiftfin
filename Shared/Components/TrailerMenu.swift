//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct TrailerMenu: View {

    @Router
    private var router

    @State
    private var error: Error?

    let localTrailers: [BaseItemDto]
    let remoteTrailers: [MediaURL]

    var body: some View {
        if localTrailers.isNotEmpty || remoteTrailers.isNotEmpty {
            ConditionalMenu(
                isMenu: (localTrailers.count + remoteTrailers.count) > 1
            ) {
                if let firstTrailer = localTrailers.first {
                    playLocalTrailer(firstTrailer)
                }

                if let firstTrailer = remoteTrailers.first {
                    playExternalTrailer(firstTrailer)
                }
            } menuContent: {
                if localTrailers.isNotEmpty {
                    Section(L10n.local) {
                        ForEach(localTrailers) { trailer in
                            Button(
                                trailer.name ?? L10n.trailer
                            ) {
                                playLocalTrailer(trailer)
                            }
                        }
                    }
                }

                if remoteTrailers.isNotEmpty {
                    Section(L10n.external) {
                        ForEach(remoteTrailers, id: \.hashValue) { mediaURL in
                            Button(
                                mediaURL.name ?? L10n.trailer
                            ) {
                                playExternalTrailer(mediaURL)
                            }
                        }
                    }
                }
            } label: {
                Label(L10n.trailers, systemImage: "movieclapper")
            }
            .errorMessage($error)
        }
    }

    private func playLocalTrailer(_ trailer: BaseItemDto) {
        router.route(to: .videoPlayer(item: trailer))
    }

    private func playExternalTrailer(_ trailer: MediaURL) {
        do {
            try UIApplication.shared.open(trailer)
        } catch {
            self.error = error
        }
    }
}
