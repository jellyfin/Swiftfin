//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
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

                UserProfileRow(user: viewModel.userSession.user.data) {
                    router.route(to: \.userProfile, viewModel)
                }

                ChevronButton(
                    L10n.server,
                    subtitle: viewModel.userSession.server.name
                )
                .onSelect {
                    router.route(to: \.serverConnection, viewModel.userSession.server)
                }

                if viewModel.userSession.user.permissions.isAdministrator {
                    ChevronButton(L10n.dashboard)
                        .onSelect {
                            router.route(to: \.adminDashboard)
                        }
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

                ChevronButton(L10n.playbackQuality)
                    .onSelect {
                        router.route(to: \.playbackQualitySettings)
                    }
            }

            Section(L10n.accessibility) {
                CaseIterablePicker(L10n.appearance, selection: $appearance)

                ChevronButton(L10n.customize)
                    .onSelect {
                        router.route(to: \.customizeViewsSettings)
                    }

                // Note: uncomment if there are current
                //       experimental settings

//                ChevronButton(L10n.experimental)
//                    .onSelect {
//                        router.route(to: \.experimentalSettings)
//                    }
            }

            Section {
                ColorPicker(L10n.accentColor, selection: $accentColor, supportsOpacity: false)
            } footer: {
                Text(L10n.viewsMayRequireRestart)
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
