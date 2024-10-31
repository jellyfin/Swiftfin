//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
    @Route(.push)
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

    // TODO: Move AdminDashboard items to its own coordinator ->
    @Route(.push)
    var userDashboard = makeUserDashboard
    @Route(.push)
    var activeSessions = makeActiveSessions
    @Route(.push)
    var activeDeviceDetails = makeActiveDeviceDetails
    @Route(.push)
    var tasks = makeTasks
    @Route(.push)
    var devices = makeDevices
    @Route(.push)
    var deviceDetails = makeDeviceDetails
    @Route(.push)
    var editServerTask = makeEditServerTask
    @Route(.modal)
    var addServerTaskTrigger = makeAddServerTaskTrigger
    @Route(.push)
    var serverLogs = makeServerLogs
    @Route(.push)
    var users = makeUsers
    @Route(.push)
    var userDetails = makeUserDetails
    @Route(.push)
    var userDevices = makeUserDevices
    @Route(.modal)
    var addServerUser = makeAddServerUser
    @Route(.push)
    var apiKeys = makeAPIKeys
    // <- End of AdminDashboard Items

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

    @ViewBuilder
    func makeResetUserPassword() -> some View {
        ResetUserPasswordView()
    }

    @ViewBuilder
    func makeLocalSecurity() -> some View {
        UserLocalSecurityView()
    }

    func makePhotoPicker(viewModel: SettingsViewModel) -> NavigationViewCoordinator<UserProfileImageCoordinator> {
        NavigationViewCoordinator(UserProfileImageCoordinator())
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

    // TODO: Move AdminDashboard items to its own coordinator ->
    @ViewBuilder
    func makeUserDashboard() -> some View {
        UserDashboardView()
    }

    @ViewBuilder
    func makeActiveSessions() -> some View {
        ActiveSessionsView()
    }

    @ViewBuilder
    func makeActiveDeviceDetails(box: BindingBox<SessionInfo?>) -> some View {
        ActiveSessionDetailView(box: box)
    }

    @ViewBuilder
    func makeTasks() -> some View {
        ServerTasksView()
    }

    @ViewBuilder
    func makeDevices() -> some View {
        DevicesView()
    }

    @ViewBuilder
    func makeDeviceDetails(device: DeviceInfo) -> some View {
        DeviceDetailsView(device: device)
    }

    @ViewBuilder
    func makeEditServerTask(observer: ServerTaskObserver) -> some View {
        EditServerTaskView(observer: observer)
    }

    func makeAddServerTaskTrigger(observer: ServerTaskObserver) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddTaskTriggerView(observer: observer)
        }
    }

    @ViewBuilder
    func makeServerLogs() -> some View {
        ServerLogsView()
    }

    @ViewBuilder
    func makeUsers() -> some View {
        ServerUsersView()
    }

    @ViewBuilder
    func makeUserDetails(user: UserDto) -> some View {
        ServerUserDetailsView(user: user)
    }

    func makeAddServerUser() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddServerUserView()
        }
    }

    @ViewBuilder
    func makeUserDevices() -> some View {
        DevicesView()
    }

    @ViewBuilder
    func makeAPIKeys() -> some View {
        APIKeysView()
    }

    // <- End of AdminDashboard Items

    #if DEBUG
    @ViewBuilder
    func makeDebugSettings() -> some View {
        DebugSettingsView()
    }
    #endif
    #endif

    #if os(tvOS)
    func makeCustomizeViewsSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator(
            BasicNavigationViewCoordinator {
                CustomizeViewsSettings()
            }
        )
    }

    func makeExperimentalSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator(
            BasicNavigationViewCoordinator {
                ExperimentalSettingsView()
            }
        )
    }

    func makeIndicatorSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            IndicatorSettingsView()
        }
    }

    func makeServerDetail(server: ServerState) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            EditServerView(server: server)
        }
    }

    func makeVideoPlayerSettings() -> NavigationViewCoordinator<VideoPlayerSettingsCoordinator> {
        NavigationViewCoordinator(
            VideoPlayerSettingsCoordinator()
        )
    }

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
