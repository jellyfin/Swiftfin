//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

#if !os(tvOS)
extension NavigationRoute {

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

    // MARK: - Active Sessions

    static let activeSessions = NavigationRoute(
        id: "activeSessions"
    ) {
        ActiveSessionsView()
    }

    static func activeDeviceDetails(box: BindingBox<SessionInfoDto?>) -> NavigationRoute {
        NavigationRoute(id: "activeDeviceDetails") {
            ActiveSessionDetailView(box: box)
        }
    }

    // MARK: - API Keys

    static let apiKeys = NavigationRoute(
        id: "apiKeys"
    ) {
        APIKeysView()
    }

    // MARK: - Devices

    static let devices = NavigationRoute(
        id: "devices"
    ) {
        DevicesView()
    }

    static func deviceDetails(device: DeviceInfoDto) -> NavigationRoute {
        NavigationRoute(id: "deviceDetails") {
            DeviceDetailsView(device: device)
        }
    }

    // MARK: - Server Logs

    static let serverLogs = NavigationRoute(
        id: "serverLogs"
    ) {
        ServerLogsView()
    }

    // MARK: - Server Tasks

    static func addServerTaskTrigger(observer: ServerTaskObserver) -> NavigationRoute {
        NavigationRoute(
            id: "addServerTaskTrigger",
            routeType: .sheet
        ) {
            AddTaskTriggerView(observer: observer)
        }
    }

    static func editServerTask(observer: ServerTaskObserver) -> NavigationRoute {
        NavigationRoute(id: "editServerTask") {
            EditServerTaskView(observer: observer)
        }
    }

    static let tasks = NavigationRoute(
        id: "tasks"
    ) {
        ServerTasksView()
    }

    // MARK: - Users

    static func addServerUser() -> NavigationRoute {
        NavigationRoute(
            id: "addServerUser",
            routeType: .sheet
        ) {
            AddServerUserView()
        }
    }

    static func quickConnectAuthorize(user: UserDto) -> NavigationRoute {
        NavigationRoute(id: "quickConnectAuthorize") {
            QuickConnectAuthorizeView(user: user)
        }
    }

    static func resetUserPasswordAdmin(userID: String) -> NavigationRoute {
        NavigationRoute(
            id: "resetUserPasswordAdmin",
            routeType: .sheet
        ) {
            ResetUserPasswordView(userID: userID, requiresCurrentPassword: false)
        }
    }

    static func userAddAccessSchedule(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userAddAccessSchedule",
            routeType: .sheet
        ) {
            AddAccessScheduleView(viewModel: viewModel)
        }
    }

    static func userAddAccessTag(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userAddAccessTag",
            routeType: .sheet
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
            routeType: .sheet
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
            routeType: .sheet
        ) {
            ServerUserLiveTVAccessView(viewModel: viewModel)
        }
    }

    static func userMediaAccess(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userMediaAccess",
            routeType: .sheet
        ) {
            ServerUserMediaAccessView(viewModel: viewModel)
        }
    }

    static func userParentalRatings(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userParentalRatings",
            routeType: .sheet
        ) {
            ServerUserParentalRatingView(viewModel: viewModel)
        }
    }

    static func userPermissions(viewModel: ServerUserAdminViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userPermissions",
            routeType: .sheet
        ) {
            ServerUserPermissionsView(viewModel: viewModel)
        }
    }

    static func userPhotoPickerAdmin(viewModel: UserProfileImageViewModel) -> NavigationRoute {
        NavigationRoute(
            id: "userPhotoPickerAdmin",
            routeType: .sheet
        ) {
            UserProfileImagePickerView()
        }
    }

    static let users = NavigationRoute(
        id: "users"
    ) {
        ServerUsersView()
    }
}
#endif
