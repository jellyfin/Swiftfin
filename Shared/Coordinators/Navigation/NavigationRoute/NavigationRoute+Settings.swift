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
            // Native rebuild on tvOS; original `OrderedSectionSelectorView` left intact for iOS.
            #if os(tvOS)
            NativeOrderedSectionSelectorView(
                title: L10n.barButtons.localizedCapitalized,
                selection: selectedButtonsBinding,
                sources: VideoPlayerActionButton.allCases
            )
            #else
            OrderedSectionSelectorView(selection: selectedButtonsBinding, sources: VideoPlayerActionButton.allCases)
                .navigationTitle(L10n.barButtons.localizedCapitalized)
            #endif
        }
    }

    static func actionMenuButtonSelector(selectedButtonsBinding: Binding<[VideoPlayerActionButton]>) -> NavigationRoute {
        NavigationRoute(id: "actionMenuButtonSelector") {
            #if os(tvOS)
            NativeOrderedSectionSelectorView(
                title: L10n.menuButtons.localizedCapitalized,
                selection: selectedButtonsBinding,
                sources: VideoPlayerActionButton.allCases
            )
            #else
            OrderedSectionSelectorView(selection: selectedButtonsBinding, sources: VideoPlayerActionButton.allCases)
                .navigationTitle(L10n.menuButtons.localizedCapitalized)
            #endif
        }
    }

    static func supplementSelector(selectedSupplementsBinding: Binding<[VideoPlayerSupplement]>) -> NavigationRoute {
        NavigationRoute(id: "supplementSelector") {
            #if os(tvOS)
            NativeOrderedSectionSelectorView(
                title: L10n.supplements.localizedCapitalized,
                selection: selectedSupplementsBinding,
                sources: VideoPlayerSupplement.allCases,
                removable: VideoPlayerSupplement.allCases.subtracting(VideoPlayerSupplement.supportedCases)
            )
            #else
            OrderedSectionSelectorView(
                selection: selectedSupplementsBinding,
                sources: VideoPlayerSupplement.allCases,
                removable: VideoPlayerSupplement.allCases.subtracting(VideoPlayerSupplement.supportedCases)
            )
            .navigationTitle(L10n.supplements.localizedCapitalized)
            #endif
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

    static func editLocalServer(server: ServerState, isEditing: Bool = false) -> NavigationRoute {
        NavigationRoute(id: "editServer") {
            // Native rebuild on tvOS; original `EditLocalServerView` left intact for iOS.
            #if os(tvOS)
            NativeEditLocalServerView(
                server: server,
                isDeletePresented: isEditing
            )
            #else
            EditLocalServerView(
                server: server,
                isDeletePresented: isEditing
            )
            #endif
        }
    }

    @MainActor
    static func serverConnections(viewModel: ServerConnectionViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "serverConnections-\(viewModel.server.id)"
        ) {
            // Native rebuild on tvOS; original `ServerConnectionsView` left intact for iOS.
            #if os(tvOS)
            NativeServerConnectionsView(viewModel: viewModel)
            #else
            ServerConnectionsView(viewModel: viewModel)
            #endif
        }
    }

    @MainActor
    static func editServerConnection(
        viewModel: ServerConnectionViewModel,
        connection: ServerConnection
    ) -> NavigationRoute {
        NavigationRoute(
            id: "serverConnection-\(viewModel.server.id)-\(connection.id)",
            style: .sheet
        ) {
            // Native rebuild on tvOS; original `EditServerConnectionView` left intact for iOS.
            #if os(tvOS)
            NativeEditServerConnectionView(
                viewModel: viewModel,
                connection: connection
            )
            #else
            EditServerConnectionView(
                viewModel: viewModel,
                connection: connection
            )
            #endif
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
            // Native rebuild on tvOS; original `FontPickerView` left intact for iOS.
            #if os(tvOS)
            NativeFontPickerView(selection: selection)
            #else
            FontPickerView(selection: selection)
            #endif
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
            WithUserAuthentication {
                // Native rebuild on tvOS; original `LocalUserSecurityView` left intact for iOS.
                #if os(tvOS)
                NativeLocalUserSecurityView()
                #else
                LocalUserSecurityView()
                #endif
            }
        }
    }

    static func localUserSettings(user: UserDto) -> NavigationRoute {
        NavigationRoute(id: "localUserSettings") {
            // Native rebuild on tvOS; original `LocalUserSettingsView` left intact for iOS.
            #if os(tvOS)
            NativeLocalUserSettingsView(user: user)
            #else
            LocalUserSettingsView(user: user)
            #endif
        }
    }

    static var log: NavigationRoute {
        NavigationRoute(
            id: "log"
        ) {
            #if os(tvOS)
            // tvOS: compact custom title + hidden system nav title (which wasted space and let log rows scroll
            // behind it). iOS keeps the stock PulseUI console. See `GuamaFlixLogsView`.
            GuamaFlixLogsView()
            #else
            ConsoleView()
            #endif
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
            // Native rebuild on tvOS; original `VideoPlayerSettingsView` left intact for iOS.
            #if os(tvOS)
            NativeVideoPlayerSettingsView()
            #else
            VideoPlayerSettingsView()
            #endif
        }
    }
}
