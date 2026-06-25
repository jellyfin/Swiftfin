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

    @Default(.VideoPlayer.nightMode)
    private var nightMode

    #if DEBUG
    @Default(.brunoDebugFPS)
    private var brunoDebugFPS
    @Default(.brunoDebugNav)
    private var brunoDebugNav
    @Default(.brunoDebugLog)
    private var brunoDebugLog
    #endif

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    // MARK: - Body

    var body: some View {
        Form(image: .jellyfinBlobBlue) {
            #if DEBUG
            debugOverlaySection
            #endif
            nightModeSection
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

    // MARK: - Debug Overlay Section

    #if DEBUG
    // Top-of-Settings switches for the on-screen debug HUD (BrunoDebugCore.swift): a frame-rate
    // window, a nav-input / layout-movement / redraw window, and a richer event log. DEBUG only.
    // swiftlint:disable hard_coded_display_string
    @ViewBuilder
    private var debugOverlaySection: some View {
        Section {
            Toggle("Frame rate", isOn: $brunoDebugFPS)
            Toggle("Nav / layout / redraws", isOn: $brunoDebugNav)
            Toggle("Event log", isOn: $brunoDebugLog)
        } header: {
            Text("Debug Overlays")
        } footer: {
            Text("On-screen HUD for diagnosing nav hitches and frame drag.")
        }
    }
    // swiftlint:enable hard_coded_display_string
    #endif

    // MARK: - Night Mode Section

    // Surfaced at the top of Settings for quick access; the same control also lives under
    // Video Player → Audio. Compresses audio dynamic range (VLC player only).
    @ViewBuilder
    private var nightModeSection: some View {
        Section {
            Group {
                #if os(iOS)
                Picker(L10n.nightMode, selection: $nightMode)
                #else
                ListRowMenu(L10n.nightMode, selection: $nightMode)
                #endif
            }
            .disabled(videoPlayerType == .native)
        } header: {
            Text(L10n.nightMode)
        } footer: {
            Text(
                videoPlayerType == .native
                    ? L10n.nightModeNativeUnsupported
                    : L10n.nightModeDescription
            )
        }
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
                L10n.swiftfin,
                value: L10n.playerSwiftfinDescription
            )
            LabeledContent(
                L10n.native,
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
