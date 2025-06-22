//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

import SwiftUI

struct SettingsView: View {

    @Default(.userAccentColor)
    private var accentColor
    @Default(.userAppearance)
    private var appearance
    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    var body: some View {
        Form {

            Section {

                UserProfileRow(user: viewModel.userSession.user.data) {
                    router.route(to: .userProfile(viewModel: viewModel))
                }

                ChevronButton(
                    L10n.server,
                    action: {
                        router.route(to: .editServer(server: viewModel.userSession.server))
                    },
                    icon: { EmptyView() },
                    subtitle: {
                        Label {
                            Text(viewModel.userSession.server.name)
                        } icon: {
                            if !viewModel.userSession.server.isVersionCompatible {
                                Image(systemName: "exclamationmark.circle.fill")
                            }
                        }
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                    }
                )

                if viewModel.userSession.user.permissions.isAdministrator {
                    ChevronButton(L10n.dashboard) {
                        router.route(to: .adminDashboard)
                    }
                }
            }

            ListRowButton(L10n.switchUser) {
                UIDevice.impact(.medium)

                viewModel.signOut()
                router.dismiss()
            }
            .foregroundStyle(accentColor.overlayColor, accentColor)

            Section(L10n.videoPlayer) {
                CaseIterablePicker(
                    L10n.videoPlayerType,
                    selection: $videoPlayerType
                )

                ChevronButton(L10n.nativePlayer) {
                    router.route(to: .nativePlayerSettings)
                }

                ChevronButton(L10n.videoPlayer) {
                    router.route(to: .videoPlayerSettings)
                }

                ChevronButton(L10n.playbackQuality) {
                    router.route(to: .playbackQualitySettings)
                }
            }

            Section(L10n.accessibility) {
                CaseIterablePicker(L10n.appearance, selection: $appearance)

                ChevronButton(L10n.customize) {
                    router.route(to: .customizeViewsSettings)
                }

                // Note: uncomment if there are current
                //       experimental settings

//                ChevronButton(L10n.experimental)
//                    .onSelect {
//                        router.route(to: .experimentalSettings)
//                    }
            }

            Section {
                ColorPicker(L10n.accentColor, selection: $accentColor, supportsOpacity: false)
            } footer: {
                Text(L10n.viewsMayRequireRestart)
            }

            ChevronButton(L10n.logs) {
                router.route(to: .log)
            }

            #if DEBUG

            ChevronButton("Debug") {
                router.route(to: .debugSettings)
            }

            #endif
        }
        .navigationTitle(L10n.settings)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
    }
}
