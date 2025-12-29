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

struct TrailerMenu: View {

    @StoredValue(.User.enabledTrailers)
    private var enabledTrailers: TrailerSelection

    @Router
    private var router

    @State
    private var error: Error?

    @StateObject
    private var localTrailerViewModel: PagingLibraryViewModel<LocalTrailerLibrary>

    private let item: BaseItemDto

    private var localTrailers: [BaseItemDto] {
        localTrailerViewModel.elements.elements
    }

    private var externalTrailers: [MediaURL] {
        (item.remoteTrailers ?? [])
            .filter {
                guard let url = URL(string: $0.url) else {
                    return false
                }
                return UIApplication.shared.canOpenURL(url)
            }
    }

    init(item: BaseItemDto) {
        self.item = item
        _localTrailerViewModel = .init(wrappedValue: .init(library: .init(parent: item)))
    }

    private var showLocalTrailers: Bool {
        enabledTrailers.contains(.local) && localTrailers.isNotEmpty
    }

    private var showExternalTrailers: Bool {
        enabledTrailers.contains(.external) && externalTrailers.isNotEmpty
    }

    var body: some View {
        ConditionalMenu(
            isMenu: (localTrailers.count + externalTrailers.count) > 1
        ) {
            if showLocalTrailers, let firstTrailer = localTrailers.first {
                playLocalTrailer(firstTrailer)
            }

            if showExternalTrailers, let firstTrailer = externalTrailers.first {
                playExternalTrailer(firstTrailer)
            }
        } menuContent: {
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
                    ForEach(externalTrailers, id: \.hashValue) { mediaURL in
                        Button(
                            mediaURL.name ?? L10n.trailer,
                            systemImage: "arrow.up.forward"
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
