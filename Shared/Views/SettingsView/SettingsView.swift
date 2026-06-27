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

    @Default(.accentColor)
    private var accentColor

    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    @Default(.VideoPlayer.Playback.appMaximumBitrate)
    private var appMaximumBitrate

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    // Advanced / playback settings are HIDDEN from the published tvOS app to keep behavior
    // server-default and low-customization: the Video Player TYPE picker, the Playback Quality page
    // (max bitrate / device profile / HDR transcode), and the Advanced (Customize) page (home /
    // poster / library / indicators / missing-episodes). The underlying views + routes are left
    // intact — flip this to `true` to restore them. iOS is unaffected (mirrors
    // `ExperimentalSettingsView.isEnabled`).
    #if os(tvOS)
    private static let showsAdvancedSettings = false
    #else
    private static let showsAdvancedSettings = true
    #endif

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
            // Hidden in production: forcing the player engine avoids users switching to Native and
            // breaking codec/transcode behavior — the server-default engine is used instead.
            if Self.showsAdvancedSettings {
                #if os(iOS)
                Picker(L10n.videoPlayerType, selection: $videoPlayerType)
                #else
                ListRowMenu(L10n.videoPlayerType, selection: $videoPlayerType)
                #endif
            }

            ChevronButton(L10n.videoPlayer) {
                router.route(to: .videoPlayerSettings)
            }

            // The full Playback Quality page is hidden in production, but Maximum Bitrate matters a lot for
            // HDR: `Auto` caps below 4K-HDR bitrates and forces a slow server transcode. So when the
            // advanced page isn't available, surface JUST this control inline — Maximum = Direct Play
            // (fast start), Auto = adaptive cap (better for slow/remote networks).
            if !Self.showsAdvancedSettings {
                #if os(iOS)
                Picker(L10n.maximumBitrate, selection: $appMaximumBitrate)
                #else
                ListRowMenu(L10n.maximumBitrate, selection: $appMaximumBitrate)
                #endif
            }

            // Hidden in production: bitrate caps / device profiles / HDR-DV force-transcode can
            // degrade or break playback. Auto / server defaults are used instead.
            if Self.showsAdvancedSettings {
                ChevronButton(L10n.playbackQuality) {
                    router.route(to: .playbackQualitySettings)
                }
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
        // Hidden in production: the Advanced (Customize) page is the bulk of the UI customization
        // (home rows, poster types, library layouts, indicators, "show missing seasons/episodes",
        // etc.) that fights the curated experience. Whole section hidden on tvOS.
        if Self.showsAdvancedSettings {
            Section {
                #if os(iOS)
                Picker(L10n.appearance, selection: $appearance)
                #endif

                ChevronButton(L10n.advanced) {
                    router.route(to: .customizeSettingsView)
                }
            } header: {
                Text(L10n.customize)
            } footer: {
                Text(L10n.viewsMayRequireRestart)
            }
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
