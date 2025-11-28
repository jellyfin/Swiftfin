//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import PulseUI
import SwiftUI

extension NavigationRoute {

    #if os(iOS)
    static func actionBarButtonSelector(selectedButtonsBinding: Binding<[VideoPlayerActionButton]>) -> NavigationRoute {
        NavigationRoute(id: "actionButtonSelector") {
            ActionButtonSelectorView(selection: selectedButtonsBinding)
                .navigationTitle(L10n.barButtons.localizedCapitalized)
        }
    }

    static func actionMenuButtonSelector(selectedButtonsBinding: Binding<[VideoPlayerActionButton]>) -> NavigationRoute {
        NavigationRoute(id: "actionButtonSelector") {
            ActionButtonSelectorView(selection: selectedButtonsBinding)
                .navigationTitle(L10n.menuButtons.localizedCapitalized)
        }
    }

    static let adminDashboard = NavigationRoute(
        id: "adminDashboard"
    ) {
        AdminDashboardView()
    }
    #endif

    static let createCustomDeviceProfile = NavigationRoute(
        id: "createCustomDeviceProfile",
        style: .sheet
    ) {
        CustomDeviceProfileSettingsView.EditCustomDeviceProfileView(profile: nil)
            .navigationTitle(L10n.customProfile.localizedCapitalized)
    }

    static let customDeviceProfileSettings = NavigationRoute(
        id: "customDeviceProfileSettings"
    ) {
        CustomDeviceProfileSettingsView()
    }

    static let customizeViewsSettings = NavigationRoute(
        id: "customizeViewsSettings"
    ) {
        CustomizeViewsSettings()
    }

    #if DEBUG && !os(tvOS)
    static let debugSettings = NavigationRoute(
        id: "debugSettings"
    ) {
        DebugSettingsView()
    }
    #endif

    static func editCustomDeviceProfile(profile: Binding<CustomDeviceProfile>) -> NavigationRoute {
        NavigationRoute(
            id: "editCustomDeviceProfile",
            style: .sheet
        ) {
            CustomDeviceProfileSettingsView.EditCustomDeviceProfileView(profile: profile)
                .navigationTitle(L10n.customProfile.localizedCapitalized)
        }
    }

    static func editCustomDeviceProfileAudio(selection: Binding<[AudioCodec]>) -> NavigationRoute {
        NavigationRoute(id: "editCustomDeviceProfileAudio") {
            OrderedSectionSelectorView(selection: selection, sources: AudioCodec.allCases)
                .navigationTitle(L10n.audio)
        }
    }

    static func editCustomDeviceProfileContainer(selection: Binding<[MediaContainer]>) -> NavigationRoute {
        NavigationRoute(id: "editCustomDeviceProfileContainer") {
            OrderedSectionSelectorView(selection: selection, sources: MediaContainer.allCases)
                .navigationTitle(L10n.containers)
        }
    }

    static func editCustomDeviceProfileVideo(selection: Binding<[VideoCodec]>) -> NavigationRoute {
        NavigationRoute(id: "editCustomDeviceProfileVideo") {
            OrderedSectionSelectorView(selection: selection, sources: VideoCodec.allCases)
                .navigationTitle(L10n.video)
        }
    }

    static func editServer(server: ServerState, isEditing: Bool = false) -> NavigationRoute {
        NavigationRoute(id: "editServer") {
            EditServerView(server: server)
                .isEditing(isEditing)
        }
    }

    static let experimentalSettings = NavigationRoute(
        id: "experimentalSettings"
    ) {
        ExperimentalSettingsView()
    }

    static func fontPicker(selection: Binding<String>) -> NavigationRoute {
        NavigationRoute(id: "fontPicker") {
            FontPickerView(selection: selection)
        }
    }

    #if os(iOS)
    static let gestureSettings = NavigationRoute(
        id: "gestureSettings"
    ) {
        GestureSettingsView()
    }
    #endif

    static let indicatorSettings = NavigationRoute(
        id: "indicatorSettings"
    ) {
        IndicatorSettingsView()
    }

    static func itemFilterDrawerSelector(selection: Binding<[ItemFilterType]>) -> NavigationRoute {
        NavigationRoute(id: "itemFilterDrawerSelector") {
            OrderedSectionSelectorView(selection: selection, sources: ItemFilterType.allCases)
                .navigationTitle(L10n.filters)
        }
    }

    static func itemOverviewView(item: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "itemOverviewView",
            style: .sheet
        ) {
            ItemOverviewView(item: item)
        }
    }

    static func itemViewAttributes(selection: Binding<[ItemViewAttribute]>) -> NavigationRoute {
        NavigationRoute(id: "itemViewAttributes") {
            OrderedSectionSelectorView(selection: selection, sources: ItemViewAttribute.allCases)
                .navigationTitle(L10n.mediaAttributes.localizedCapitalized)
        }
    }

    static let localSecurity = NavigationRoute(
        id: "localSecurity"
    ) {
        UserLocalSecurityView()
    }

    static let log = NavigationRoute(
        id: "log"
    ) {
        ConsoleView()
    }

    #if os(iOS)
    static let nativePlayerSettings = NavigationRoute(
        id: "nativePlayerSettings"
    ) {
        NativeVideoPlayerSettingsView()
    }
    #endif

    static let playbackQualitySettings = NavigationRoute(
        id: "playbackQualitySettings"
    ) {
        PlaybackQualitySettingsView()
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

    static let settings = NavigationRoute(
        id: "settings",
        style: .sheet
    ) {
        SettingsView()
    }

    static func userProfile(viewModel: SettingsViewModel) -> NavigationRoute {
        NavigationRoute(id: "userProfile") {
            UserProfileSettingsView(viewModel: viewModel)
        }
    }

    static let videoPlayerSettings = NavigationRoute(
        id: "videoPlayerSettings"
    ) {
        VideoPlayerSettingsView()
    }
}
