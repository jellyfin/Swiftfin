//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import PulseUI
import SwiftUI

extension NavigationRoute {

    static func actionBarButtonSelector(selectedButtonsBinding: Binding<[VideoPlayerActionButton]>) -> NavigationRoute {
        NavigationRoute(id: "actionBarButtonSelector") {
            OrderedSectionSelectorView(selection: selectedButtonsBinding, sources: VideoPlayerActionButton.allCases)
                .navigationTitle(L10n.barButtons.localizedCapitalized)
        }
    }

    static func actionMenuButtonSelector(selectedButtonsBinding: Binding<[VideoPlayerActionButton]>) -> NavigationRoute {
        NavigationRoute(id: "actionMenuButtonSelector") {
            OrderedSectionSelectorView(selection: selectedButtonsBinding, sources: VideoPlayerActionButton.allCases)
                .navigationTitle(L10n.menuButtons.localizedCapitalized)
        }
    }

    #if os(iOS)
    static var adminDashboard: NavigationRoute {
        NavigationRoute(
            id: "adminDashboard"
        ) {
            AdminDashboardView()
        }
    }
    #endif

    static var createDeviceProfile: NavigationRoute {
        NavigationRoute(
            id: "createDeviceProfile",
            style: .sheet
        ) {
            CustomDeviceProfilesView.EditDeviceProfileView(profile: nil)
                .navigationTitle(L10n.customProfile.localizedCapitalized)
        }
    }

    static var customDeviceProfilesSettings: NavigationRoute {
        NavigationRoute(
            id: "customDeviceProfilesSettings"
        ) {
            CustomDeviceProfilesView()
        }
    }

    static var customizeSettingsView: NavigationRoute {
        NavigationRoute(
            id: "customizeSettingsView"
        ) {
            CustomizeSettingsView()
        }
    }

    #if DEBUG
    static var debugSettings: NavigationRoute {
        NavigationRoute(
            id: "debugSettings"
        ) {
            DebugSettingsView()
        }
    }
    #endif

    static func editDeviceProfile(profile: Binding<CustomDeviceProfile>) -> NavigationRoute {
        NavigationRoute(
            id: "editDeviceProfile",
            style: .sheet
        ) {
            CustomDeviceProfilesView.EditDeviceProfileView(profile: profile)
                .navigationTitle(L10n.customProfile.localizedCapitalized)
        }
    }

    static func editDeviceProfileAudio(selection: Binding<[AudioCodec]>) -> NavigationRoute {
        NavigationRoute(id: "editDeviceProfileAudio") {
            OrderedSectionSelectorView(systemImage: "waveform", selection: selection, sources: AudioCodec.allCases)
                .navigationTitle(L10n.audio)
        }
    }

    static func editDeviceProfileContainer(selection: Binding<[MediaContainer]>) -> NavigationRoute {
        NavigationRoute(id: "editDeviceProfileContainer") {
            OrderedSectionSelectorView(systemImage: "archivebox", selection: selection, sources: MediaContainer.allCases)
                .navigationTitle(L10n.containers)
        }
    }

    static func editDeviceProfileVideo(selection: Binding<[VideoCodec]>) -> NavigationRoute {
        NavigationRoute(id: "editDeviceProfileVideo") {
            OrderedSectionSelectorView(systemImage: "play.rectangle", selection: selection, sources: VideoCodec.allCases)
                .navigationTitle(L10n.video)
        }
    }

    static func editServer(server: ServerState, isEditing: Bool = false) -> NavigationRoute {
        NavigationRoute(id: "editServer") {
            EditServerView(server: server)
                .isEditing(isEditing)
        }
    }

    static var experimentalSettings: NavigationRoute {
        NavigationRoute(
            id: "experimentalSettings"
        ) {
            ExperimentalSettingsView()
        }
    }

    static func fontPicker(selection: Binding<String>) -> NavigationRoute {
        NavigationRoute(id: "fontPicker") {
            FontPickerView(selection: selection)
        }
    }

    #if os(iOS)
    static var gestureSettings: NavigationRoute {
        NavigationRoute(
            id: "gestureSettings"
        ) {
            GestureSettingsView()
        }
    }
    #endif

    static var indicatorSettings: NavigationRoute {
        NavigationRoute(
            id: "indicatorSettings"
        ) {
            IndicatorSettingsView()
        }
    }

    static func itemFilterDrawerSelector(selection: Binding<[ItemFilterType]>) -> NavigationRoute {
        NavigationRoute(id: "itemFilterDrawerSelector") {
            OrderedSectionSelectorView(systemImage: "line.3.horizontal.decrease", selection: selection, sources: ItemFilterType.allCases)
                .navigationTitle(L10n.filters)
        }
    }

    static func itemViewAttributes(selection: Binding<[ItemViewAttribute]>) -> NavigationRoute {
        NavigationRoute(id: "itemViewAttributes") {
            OrderedSectionSelectorView(systemImage: "tag", selection: selection, sources: ItemViewAttribute.allCases)
                .navigationTitle(L10n.mediaAttributes.localizedCapitalized)
        }
    }

    static var localUserSecurity: NavigationRoute {
        NavigationRoute(
            id: "localUserSecurity"
        ) {
            LocalUserSecurityView()
        }
    }

    static func localUserSettings(viewModel: SettingsViewModel) -> NavigationRoute {
        NavigationRoute(id: "localUserSettings") {
            LocalUserSettingsView(viewModel: viewModel)
        }
    }

    static var log: NavigationRoute {
        NavigationRoute(
            id: "log"
        ) {
            ConsoleView()
        }
    }

    static var playbackQualitySettings: NavigationRoute {
        NavigationRoute(
            id: "playbackQualitySettings"
        ) {
            PlaybackQualitySettingsView()
        }
    }

    #if os(iOS)
    static func resetUserPassword(userID: String) -> NavigationRoute {
        NavigationRoute(
            id: "resetUserPassword",
            style: .sheet
        ) {
            ResetUserPasswordView(userID: userID, requiresCurrentPassword: true)
        }
    }
    #endif

    static func serverConnection(server: ServerState) -> NavigationRoute {
        NavigationRoute(id: "serverConnection") {
            EditServerView(server: server)
        }
    }

    static var settings: NavigationRoute {
        NavigationRoute(
            id: "settings",
            style: .sheet
        ) {
            SettingsView()
        }
    }

    static var videoPlayerSettings: NavigationRoute {
        NavigationRoute(
            id: "videoPlayerSettings"
        ) {
            VideoPlayerSettingsView()
        }
    }
}
