//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreData
import Defaults
import Factory
import Stinsen
import SwiftUI

struct SettingsView: View {

    @Default(.userAccentColor)
    private var accentColor

    @Default(.userAppearance)
    private var appearance
    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @StateObject
    private var viewModel = SettingsViewModel()

    var body: some View {
        Form {

            Section {

                UserProfileRow {
                    router.route(to: \.userProfile, viewModel)
                }

                // TODO: admin users go to dashboard instead
                ChevronButton(
                    L10n.server,
                    subtitle: viewModel.userSession.server.name
                )
                .onSelect {
                    router.route(to: \.serverDetail, viewModel.userSession.server)
                }
            }

            ListRowButton(L10n.switchUser) {
                UIDevice.impact(.medium)

                router.dismissCoordinator {
                    viewModel.signOut()
                }
            }
            .foregroundStyle(accentColor.overlayColor, accentColor)

            Section(L10n.videoPlayer) {
                CaseIterablePicker(
                    L10n.videoPlayerType,
                    selection: $videoPlayerType
                )

                ChevronButton(L10n.nativePlayer)
                    .onSelect {
                        router.route(to: \.nativePlayerSettings)
                    }

                ChevronButton(L10n.videoPlayer)
                    .onSelect {
                        router.route(to: \.videoPlayerSettings)
                    }

                ChevronButton(L10n.maximumBitrate)
                    .onSelect {
                        router.route(to: \.maximumBitrateSettings)
                    }
            }

            Section(L10n.accessibility) {
                CaseIterablePicker(L10n.appearance, selection: $appearance)

                ChevronButton(L10n.customize)
                    .onSelect {
                        router.route(to: \.customizeViewsSettings)
                    }

                ChevronButton(L10n.experimental)
                    .onSelect {
                        router.route(to: \.experimentalSettings)
                    }
            }

            Section {
                ColorPicker(L10n.accentColor, selection: $accentColor, supportsOpacity: false)
            } footer: {
                Text(L10n.accentColorDescription)
            }

            ChevronButton(L10n.logs)
                .onSelect {
                    router.route(to: \.log)
                }

            #if DEBUG

            ChevronButton("Debug")
                .onSelect {
                    router.route(to: \.debugSettings)
                }

            #endif
        }
        .navigationTitle(L10n.settings)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }
}
