//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

#if os(iOS)
extension NavigationRoute {

    // MARK: - Active Sessions

    static func activeDeviceDetails(box: BindingBox<SessionInfoDto?>) -> NavigationRoute {
        NavigationRoute(id: "activeDeviceDetails") {
            ActiveSessionDetailView(box: box)
        }
    }

    static let activeSessions = NavigationRoute(
        id: "activeSessions"
    ) {
        ActiveSessionsView()
    }

    // MARK: - User Activity

    static let activity = NavigationRoute(
        id: "activity"
    ) {
        ServerActivityView()
    }

    static func activityDetails(viewModel: ServerActivityDetailViewModel) -> NavigationRoute {
        NavigationRoute(id: "activityDetails") {
            ServerActivityDetailsView(viewModel: viewModel)
        }
    }

    static func activityFilters(viewModel: ServerActivityViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "activityFilters",
            style: .sheet
        ) {
            ServerActivityFilterView(viewModel: viewModel)
        }
    }

    // MARK: - Server Tasks

    static func addServerTaskTrigger(observer: ServerTaskObserver) -> NavigationRoute {
        NavigationRoute(
            id: "addServerTaskTrigger",
            style: .sheet
        ) {
            AddTaskTriggerView(observer: observer)
        }
    }

    // MARK: - Users

    static func addServerUser() -> NavigationRoute {
        NavigationRoute(
            id: "addServerUser",
            style: .sheet
        ) {
            AddServerUserView()
        }
    }

    // MARK: - API Keys

    static let apiKeys = NavigationRoute(
        id: "apiKeys"
    ) {
        APIKeysView()
    }

    // MARK: - Devices

    static func deviceDetails(device: DeviceInfoDto, viewModel: DevicesViewModel) -> NavigationRoute {
        NavigationRoute(id: "deviceDetails") {
            DeviceDetailsView(device: device, viewModel: viewModel)
        }
    }

    static let devices = NavigationRoute(
        id: "devices"
    ) {
        DevicesView()
    }

    // MARK: - Server Tasks

    static func editServerTask(observer: ServerTaskObserver) -> NavigationRoute {
        NavigationRoute(id: "editServerTask") {
            EditServerTaskView(observer: observer)
        }
    }

    // MARK: - Users

    static func quickConnectAuthorize(user: UserDto) -> NavigationRoute {
        NavigationRoute(id: "quickConnectAuthorize") {
            QuickConnectAuthorizeView(user: user)
        }
    }

    static func resetUserPasswordAdmin(userID: String) -> NavigationRoute {
        NavigationRoute(
            id: "resetUserPasswordAdmin",
            style: .sheet
        ) {
            ResetUserPasswordView(userID: userID, requiresCurrentPassword: false)
        }
    }

    // MARK: - Server Logs

    static let serverLogs = NavigationRoute(
        id: "serverLogs"
    ) {
        ServerLogsView()
    }

    // MARK: - Server Tasks

    static let tasks = NavigationRoute(
        id: "tasks"
    ) {
        ServerTasksView()
    }

    // MARK: - Users

    static func userAddAccessSchedule(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userAddAccessSchedule",
            style: .sheet
        ) {
            AddAccessScheduleView(viewModel: viewModel)
        }
    }

    static func userAddAccessTag(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userAddAccessTag",
            style: .sheet
        ) {
            AddServerUserAccessTagsView(viewModel: viewModel)
        }
    }

    static func userDetails(user: UserDto) -> NavigationRoute {
        NavigationRoute(id: "userDetails") {
            ServerUserDetailsView(user: user)
        }
    }

    static func userDeviceAccess(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userDeviceAccess",
            style: .sheet
        ) {
            ServerUserDeviceAccessView(viewModel: viewModel)
        }
    }

    static func userEditAccessSchedules(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(id: "userEditAccessSchedules") {
            EditAccessScheduleView(viewModel: viewModel)
        }
    }

    static func userEditAccessTags(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(id: "userEditAccessTags") {
            EditServerUserAccessTagsView(viewModel: viewModel)
        }
    }

    static func userLiveTVAccess(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userLiveTVAccess",
            style: .sheet
        ) {
            ServerUserLiveTVAccessView(viewModel: viewModel)
        }
    }

    static func userMediaAccess(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userMediaAccess",
            style: .sheet
        ) {
            ServerUserMediaAccessView(viewModel: viewModel)
        }
    }

    static func userParentalRatings(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userParentalRatings",
            style: .sheet
        ) {
            ServerUserParentalRatingView(viewModel: viewModel)
        }
    }

    static func userPermissions(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userPermissions",
            style: .sheet
        ) {
            ServerUserPermissionsView(viewModel: viewModel)
        }
    }

    static let users = NavigationRoute(
        id: "users"
    ) {
        ServerUsersView()
    }
}
#endif
