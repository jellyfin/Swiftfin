//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Logging
import SwiftUI

extension ItemActionButtons {

    struct Trailers: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        @StoredValue(.User.enabledTrailers)
        private var enabledTrailers: TrailerSelection

        @ViewContextContains(.isInMenu)
        private var isInMenu

        @Router
        private var router

        @State
        private var error: Error?

        private let logger = Logger.swiftfin()

        private var localTrailers: [BaseItemDto] {
            provider.localTrailers
        }

        private var externalTrailers: [NamedURL] {
            provider.item.remoteTrailers ?? []
        }

        private var showLocalTrailers: Bool {
            enabledTrailers.contains(.local) && localTrailers.isNotEmpty
        }

        private var showExternalTrailers: Bool {
            enabledTrailers.contains(.external) && externalTrailers.isNotEmpty
        }

        private var label: ItemActionButtonLabel {
            ItemActionButtonLabel(.trailers)
        }

        @ViewBuilder
        private var trailerButton: some View {
            Button {
                if showLocalTrailers, let firstTrailer = localTrailers.first {
                    playLocalTrailer(firstTrailer)
                }

                if showExternalTrailers, let firstTrailer = externalTrailers.first {
                    playExternalTrailer(firstTrailer)
                }
            } label: {
                label
            }
        }

        @ViewBuilder
        private var menuContent: some View {
            Group {
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
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary)
        }

        @ViewBuilder
        private var trailerMenu: some View {
            Menu {
                menuContent
            } label: {
                label
            }
            .if(!isInMenu && UIDevice.isTV) { menu in
                menu.menuStyle(.button)
            }
        }

        private func playLocalTrailer(_ trailer: BaseItemDto) {
            guard let provider = trailer.getPlaybackItemProvider(userSession: nil) else {
                logger.log(level: .error, "Unable to build provider")
                error = ErrorMessage(L10n.unknownError)
                return
            }

            router.route(to: .videoPlayer(provider: provider))
        }

        private func playExternalTrailer(_ trailer: NamedURL) {
            #if os(tvOS)
            guard let urlString = trailer.url,
                  let externalURL = ExternalTrailerURL(string: urlString)
            else {
                error = ErrorMessage(L10n.unableToOpenTrailer)
                return
            }

            guard externalURL.canBeOpened else {
                error = ErrorMessage(L10n.unableToOpenTrailer)
                return
            }

            UIApplication.shared.open(externalURL.deepLink) { success in
                if !success {
                    error = ErrorMessage(L10n.unableToOpenTrailerApp(externalURL.source.displayTitle))
                }
            }
            #else
            guard let url = URL(string: trailer.url), UIApplication.shared.canOpenURL(url) else {
                error = ErrorMessage(L10n.unableToOpenTrailer)
                return
            }

            UIApplication.shared.open(url) { success in
                if !success {
                    error = ErrorMessage(L10n.unableToOpenTrailer)
                }
            }
            #endif
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
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary, .secondary)
        }
    }
}
