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

final class AdminDashboardCoordinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \AdminDashboardCoordinator.start)

    @Root
    var start = makeStart

    @Route(.push)
    var activeSessions = makeActiveSessions
    @Route(.push)
    var activeDeviceDetails = makeActiveDeviceDetails
    @Route(.push)
    var devices = makeDevices
    @Route(.push)
    var tasks = makeTasks
    @Route(.push)
    var users = makeUsers
    @Route(.push)
    var userDetails = makeUserDetails
    @Route(.push)
    var editScheduledTask = makeEditScheduledTask
    @Route(.modal)
    var addScheduledTaskTrigger = makeAddScheduledTaskTrigger
    @Route(.push)
    var serverLogs = makeServerLogs

    @ViewBuilder
    func makeActiveSessions() -> some View {
        ActiveSessionsView()
    }

    @ViewBuilder
    func makeActiveDeviceDetails(box: BindingBox<SessionInfo?>) -> some View {
        ActiveSessionDetailView(box: box)
    }

    @ViewBuilder
    func makeDevices() -> some View {
        DevicesView()
    }

    @ViewBuilder
    func makeTasks() -> some View {
        ScheduledTasksView()
    }

    @ViewBuilder
    func makeUsers() -> some View {
        UserAdministrationView()
    }

    @ViewBuilder
    func makeUserDetails(observer: UserAdministrationObserver) -> some View {
        UserAdministrationDetailView(observer: observer)
    }

    @ViewBuilder
    func makeEditScheduledTask(observer: ServerTaskObserver) -> some View {
        EditScheduledTaskView(observer: observer)
    }

    func makeAddScheduledTaskTrigger(observer: ServerTaskObserver) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            AddTaskTriggerView(observer: observer)
        }
    }

    @ViewBuilder
    func makeServerLogs() -> some View {
        ServerLogsView()
    }

    @ViewBuilder
    func makeStart() -> some View {
        AdminDashboardView()
    }
}
