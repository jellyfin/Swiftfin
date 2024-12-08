//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Stinsen
import SwiftUI

final class AdminDashboardCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \AdminDashboardCoordinator.start)

    @Root
    var start = makeStart

    // MARK: - Route: Active Sessions

    @Route(.push)
    var activeSessions = makeActiveSessions
    @Route(.push)
    var activeDeviceDetails = makeActiveDeviceDetails

    // MARK: - Route: Devices

    @Route(.push)
    var devices = makeDevices
    @Route(.push)
    var deviceDetails = makeDeviceDetails

    // MARK: - Route: Server Tasks

    @Route(.push)
    var editServerTask = makeEditServerTask
    @Route(.push)
    var tasks = makeTasks
    @Route(.modal)
    var addServerTaskTrigger = makeAddServerTaskTrigger

    // MARK: - Route: Server Logs

    @Route(.push)
    var serverLogs = makeServerLogs

    // MARK: - Route: Users

    @Route(.push)
    var users = makeUsers
    @Route(.push)
    var userDetails = makeUserDetails
    @Route(.modal)
    var userMediaAccess = makeUserMediaAccess
    @Route(.modal)
    var userPermissions = makeUserPermissions
    @Route(.modal)
    var resetUserPassword = makeResetUserPassword
    @Route(.modal)
    var addServerUser = makeAddServerUser

    // MARK: - Route: API Keys

    @Route(.push)
    var apiKeys = makeAPIKeys

    // MARK: - Views: Active Sessions

    @ViewBuilder
    func makeActiveSessions() -> some View {
        ActiveSessionsView()
    }

    @ViewBuilder
    func makeActiveDeviceDetails(box: BindingBox<SessionInfo?>) -> some View {
        ActiveSessionDetailView(box: box)
    }

    // MARK: - Views: Server Tasks

    @ViewBuilder
    func makeTasks() -> some View {
        ServerTasksView()
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

    // MARK: - Views: Devices

    @ViewBuilder
    func makeDevices() -> some View {
        DevicesView()
    }

    @ViewBuilder
    func makeDeviceDetails(device: DeviceInfo) -> some View {
        DeviceDetailsView(device: device)
    }

    // MARK: - Views: Server Logs

    @ViewBuilder
    func makeServerLogs() -> some View {
        ServerLogsView()
    }

    // MARK: - Views: Users

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

    func makeUserMediaAccess(viewModel: ServerUserAdminViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ServerUserAccessView(viewModel: viewModel)
        }
    }

    func makeUserPermissions(viewModel: ServerUserAdminViewModel) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ServerUserPermissionsView(viewModel: viewModel)
        }
    }

    func makeResetUserPassword(userID: String) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ResetUserPasswordView(userID: userID, requiresCurrentPassword: false)
        }
    }

    // MARK: - Views: API Keys

    @ViewBuilder
    func makeAPIKeys() -> some View {
        APIKeysView()
    }

    // MARK: - Views: Dashboard

    @ViewBuilder
    func makeStart() -> some View {
        AdminDashboardView()
    }
}
