//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import PulseUI
import Stinsen
import SwiftUI

final class SettingsCoordinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \SettingsCoordinator.start)

    @Root
    var start = makeStart

    #if os(iOS)
    @Route(.push)
    var log = makeLog
    @Route(.push)
    var nativePlayerSettings = makeNativePlayerSettings
    @Route(.push)
    var playbackQualitySettings = makePlaybackQualitySettings
    @Route(.push)
    var quickConnect = makeQuickConnectAuthorize
    @Route(.modal)
    var resetUserPassword = makeResetUserPassword
    @Route(.push)
    var localSecurity = makeLocalSecurity
    @Route(.modal)
    var photoPicker = makePhotoPicker
    @Route(.push)
    var userProfile = makeUserProfileSettings

    @Route(.push)
    var customizeViewsSettings = makeCustomizeViewsSettings
    @Route(.push)
    var experimentalSettings = makeExperimentalSettings
    @Route(.push)
    var itemFilterDrawerSelector = makeItemFilterDrawerSelector
    @Route(.push)
    var indicatorSettings = makeIndicatorSettings
    @Route(.push)
    var itemViewAttributes = makeItemViewAttributes
    @Route(.push)
    var serverConnection = makeServerConnection
    @Route(.push)
    var videoPlayerSettings = makeVideoPlayerSettings
    @Route(.push)
    var customDeviceProfileSettings = makeCustomDeviceProfileSettings
    @Route(.modal)
    var itemOverviewView = makeItemOverviewView

    @Route(.modal)
    var editCustomDeviceProfile = makeEditCustomDeviceProfile
    @Route(.modal)
    var createCustomDeviceProfile = makeCreateCustomDeviceProfile

    @Route(.push)
    var adminDashboard = makeAdminDashboard

    #if DEBUG
    @Route(.push)
    var debugSettings = makeDebugSettings
    #endif
    #endif

    #if os(tvOS)
    @Route(.modal)
    var customizeViewsSettings = makeCustomizeViewsSettings
    @Route(.modal)
    var experimentalSettings = makeExperimentalSettings
    @Route(.modal)
    var log = makeLog
    @Route(.modal)
    var serverDetail = makeServerDetail
    @Route(.modal)
    var videoPlayerSettings = makeVideoPlayerSettings
    @Route(.modal)
    var playbackQualitySettings = makePlaybackQualitySettings
    @Route(.modal)
    var userProfile = makeUserProfileSettings
    #endif

    #if os(iOS)
    @ViewBuilder
    func makeNativePlayerSettings() -> some View {
        NativeVideoPlayerSettingsView()
    }

    @ViewBuilder
    func makePlaybackQualitySettings() -> some View {
        PlaybackQualitySettingsView()
    }

    @ViewBuilder
    func makeCustomDeviceProfileSettings() -> some View {
        CustomDeviceProfileSettingsView()
    }

    func makeEditCustomDeviceProfile(profile: Binding<CustomDeviceProfile>)
        -> NavigationViewCoordinator<EditCustomDeviceProfileCoordinator>
    {
        NavigationViewCoordinator(EditCustomDeviceProfileCoordinator(profile: profile))
    }

    func makeCreateCustomDeviceProfile() -> NavigationViewCoordinator<EditCustomDeviceProfileCoordinator> {
        NavigationViewCoordinator(EditCustomDeviceProfileCoordinator())
    }

    @ViewBuilder
    func makeQuickConnectAuthorize() -> some View {
        QuickConnectAuthorizeView()
    }

    func makeResetUserPassword(userID: String) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ResetUserPasswordView(userID: userID, requiresCurrentPassword: true)
        }
    }

    @ViewBuilder
    func makeLocalSecurity() -> some View {
        UserLocalSecurityView()
    }

    func makePhotoPicker(viewModel: UserProfileImageViewModel) -> NavigationViewCoordinator<UserProfileImageCoordinator> {
        NavigationViewCoordinator(UserProfileImageCoordinator(viewModel: viewModel))
    }

    @ViewBuilder
    func makeUserProfileSettings(viewModel: SettingsViewModel) -> some View {
        UserProfileSettingsView(viewModel: viewModel)
    }

    @ViewBuilder
    func makeCustomizeViewsSettings() -> some View {
        CustomizeViewsSettings()
    }

    @ViewBuilder
    func makeExperimentalSettings() -> some View {
        ExperimentalSettingsView()
    }

    @ViewBuilder
    func makeIndicatorSettings() -> some View {
        IndicatorSettingsView()
    }

    @ViewBuilder
    func makeItemViewAttributes(selection: Binding<[ItemViewAttribute]>) -> some View {
        OrderedSectionSelectorView(selection: selection, sources: ItemViewAttribute.allCases)
            .navigationTitle(L10n.mediaAttributes.localizedCapitalized)
    }

    @ViewBuilder
    func makeServerConnection(server: ServerState) -> some View {
        EditServerView(server: server)
    }

    func makeItemOverviewView(item: BaseItemDto) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ItemOverviewView(item: item)
        }
    }

    func makeItemFilterDrawerSelector(selection: Binding<[ItemFilterType]>) -> some View {
        OrderedSectionSelectorView(selection: selection, sources: ItemFilterType.allCases)
            .navigationTitle(L10n.filters)
    }

    func makeVideoPlayerSettings() -> VideoPlayerSettingsCoordinator {
        VideoPlayerSettingsCoordinator()
    }

    @ViewBuilder
    func makeAdminDashboard() -> some View {
        AdminDashboardCoordinator().view()
    }

    #if DEBUG
    @ViewBuilder
    func makeDebugSettings() -> some View {
        DebugSettingsView()
    }
    #endif
    #endif

    #if os(tvOS)

    // MARK: - User Profile View

    func makeUserProfileSettings(viewModel: SettingsViewModel) -> NavigationViewCoordinator<UserProfileSettingsCoordinator> {
        NavigationViewCoordinator(
            UserProfileSettingsCoordinator(viewModel: viewModel)
        )
    }

    // MARK: - Customize Settings View

    func makeCustomizeViewsSettings() -> NavigationViewCoordinator<CustomizeSettingsCoordinator> {
        NavigationViewCoordinator(
            CustomizeSettingsCoordinator()
        )
    }

    // MARK: - Experimental Settings View

    func makeExperimentalSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator(
            BasicNavigationViewCoordinator {
                ExperimentalSettingsView()
            }
        )
    }

    // MARK: - Poster Indicator Settings View

    func makeIndicatorSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            IndicatorSettingsView()
        }
    }

    // MARK: - Server Settings View

    func makeServerDetail(server: ServerState) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            EditServerView(server: server)
        }
    }

    // MARK: - Video Player Settings View

    func makeVideoPlayerSettings() -> NavigationViewCoordinator<VideoPlayerSettingsCoordinator> {
        NavigationViewCoordinator(
            VideoPlayerSettingsCoordinator()
        )
    }

    // MARK: - Playback Settings View

    func makePlaybackQualitySettings() -> NavigationViewCoordinator<PlaybackQualitySettingsCoordinator> {
        NavigationViewCoordinator(
            PlaybackQualitySettingsCoordinator()
        )
    }
    #endif

    @ViewBuilder
    func makeLog() -> some View {
        ConsoleView()
    }

    @ViewBuilder
    func makeStart() -> some View {
        SettingsView()
    }
}
