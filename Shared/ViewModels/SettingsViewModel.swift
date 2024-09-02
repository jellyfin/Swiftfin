//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Files
import Foundation
import JellyfinAPI
import UIKit

// TODO: should probably break out into a `Settings` and `AppSettings` view models
//       - don't need delete user profile image from app settings
//       - could clean up all settings view models

final class SettingsViewModel: ViewModel {

    @Published
    var currentAppIcon: any AppIcon = PrimaryAppIcon.primary
    @Published
    var servers: [ServerState] = []

    override init() {

        guard let iconName = UIApplication.shared.alternateIconName else {
            currentAppIcon = PrimaryAppIcon.primary
            super.init()
            return
        }

        if let appicon = PrimaryAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
        }

        if let appicon = DarkAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
        }

        if let appicon = InvertedDarkAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
        }

        if let appicon = InvertedLightAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
        }

        if let appicon = LightAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
        }

        super.init()

        do {
            servers = try getServers()
        } catch {
            logger.critical("Could not retrieve servers")
        }
    }

    func deleteCurrentUserProfileImage() {
        Task {
            let request = Paths.deleteUserImage(
                userID: userSession.user.id,
                imageType: "Primary"
            )
            let _ = try await userSession.client.send(request)

            let currentUserRequest = Paths.getCurrentUser
            let response = try await userSession.client.send(currentUserRequest)

            await MainActor.run {
                userSession.user.data = response.value

                Notifications[.didChangeUserProfileImage].post()
            }
        }
    }

    func select(icon: any AppIcon) {
        let previousAppIcon = currentAppIcon
        currentAppIcon = icon

        Task { @MainActor in

            do {
                if case PrimaryAppIcon.primary = icon {
                    try await UIApplication.shared.setAlternateIconName(nil)
                } else {
                    try await UIApplication.shared.setAlternateIconName(icon.iconName)
                }
            } catch {
                logger.error("Unable to update app icon to \(icon.iconName): \(error.localizedDescription)")
                currentAppIcon = previousAppIcon
            }
        }
    }

    private func getServers() throws -> [ServerState] {
        try SwiftfinStore
            .dataStack
            .fetchAll(From<ServerModel>())
            .map(\.state)
            .sorted(using: \.name)
    }

    func signOut() {
        Defaults[.lastSignedInUserID] = .signedOut
        Container.shared.currentUserSession.reset()
        Notifications[.didSignOut].post()
    }
}
