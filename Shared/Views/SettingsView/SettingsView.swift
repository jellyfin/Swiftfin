//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct SettingsView: View {

    #if os(iOS)
    @Default(.userAppearance)
    private var appearance
    #endif

    @Default(.userAccentColor)
    private var accentColor

    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    // MARK: - Body

    var body: some View {
        Form(image: .jellyfinBlobBlue) {
            serverSection
            videoPlayerSection
            customizeSection
            diagnosticsSection
        }
        #if os(iOS)
        .navigationTitle(L10n.settings)
        .navigationBarCloseButton {
            router.dismiss()
        }
        #endif
    }

    // MARK: - Server Section

    @ViewBuilder
    private var serverSection: some View {
        if let userSession = viewModel.userSession {
            Section {
                UserProfileRow(user: userSession.user.data) {
                    router.route(to: .localUserSettings(user: userSession.user.data))
                }

                ChevronButton(
                    L10n.server,
                    action: {
                        router.route(to: .editLocalServer(server: userSession.server))
                    }
                ) {
                    Label {
                        Text(userSession.server.name)
                    } icon: {
                        if !userSession.server.isVersionCompatible {
                            Image(systemName: "exclamationmark.circle.fill")
                        }
                    }
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }

                #if os(iOS)
                if userSession.user.data.policy?.isAdministrator == true {
                    ChevronButton(L10n.dashboard) {
                        router.route(to: .adminDashboard)
                    }
                }
                #endif
            }
        }

        Section {
            Button(L10n.switchUser) {
                UIDevice.impact(.medium)
                viewModel.signOut()
                router.dismiss()
            }
            .buttonStyle(.primary)
            .foregroundStyle(accentColor.overlayColor, accentColor)
        }
    }

    // MARK: - Video Player Section

    @ViewBuilder
    private var videoPlayerSection: some View {
        Section(L10n.videoPlayer) {
            #if os(iOS)
            Picker(L10n.videoPlayerType, selection: $videoPlayerType)
            #else
            ListRowMenu(L10n.videoPlayerType, selection: $videoPlayerType)
            #endif

            ChevronButton(L10n.videoPlayer) {
                router.route(to: .videoPlayerSettings)
            }

            ChevronButton(L10n.playbackQuality) {
                router.route(to: .playbackQualitySettings)
            }
        } learnMore: {
            LabeledContent(
                L10n.vlc,
                value: L10n.playerSwiftfinDescription
            )
            LabeledContent(
                L10n.avPlayer,
                value: L10n.playerNativeDescription
            )
        }
    }

    // MARK: - Customization Section

    @ViewBuilder
    private var customizeSection: some View {
        Section {
            #if os(iOS)
            Picker(L10n.appearance, selection: $appearance)
            #endif

            ColorPicker(L10n.accentColor, selection: $accentColor, supportsOpacity: false)

            ChevronButton(L10n.advanced) {
                router.route(to: .customizeSettingsView)
            }
        } header: {
            Text(L10n.customize)
        } footer: {
            Text(L10n.viewsMayRequireRestart)
        }
    }

    // MARK: - Diagnostics Section

    @ViewBuilder
    private var diagnosticsSection: some View {
        Section {

            if ExperimentalSettingsView.isEnabled {
                ChevronButton(L10n.experimental) {
                    router.route(to: .experimentalSettings)
                }
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
    }
}
