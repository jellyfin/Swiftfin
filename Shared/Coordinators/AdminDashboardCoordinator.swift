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
    @Route(.modal)
    var resetUserPassword = makeResetUserPassword
    @Route(.modal)
    var addServerUser = makeAddServerUser
    @Route(.push)
    var apiKeys = makeAPIKeys

    @ViewBuilder
    func makeAdminDashboard() -> some View {
        AdminDashboardView()
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

    func makeResetUserPassword(userID: String) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ResetUserPasswordView(userID: userID, requiresCurrentPassword: false)
        }
    }

    @ViewBuilder
    func makeAPIKeys() -> some View {
        APIKeysView()
    }

    @ViewBuilder
    func makeStart() -> some View {
        AdminDashboardView()
    }
}
