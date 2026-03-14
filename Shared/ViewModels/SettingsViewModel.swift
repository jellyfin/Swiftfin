//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Files
import Foundation
import JellyfinAPI
import UIKit

// TODO: should probably break out into a `Settings` and `AppSettings` view models
//       - could clean up all settings view models

final class SettingsViewModel: ViewModel {

    @Published
    var currentAppIcon: any AppIcon = PrimaryAppIcon.primary
    @Published
    var servers: [ServerState] = []

    override init() {

        if let iconName = UIApplication.shared.alternateIconName {
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
        } else {
            currentAppIcon = PrimaryAppIcon.primary
        }

        super.init()

        do {
            servers = try getServers()
        } catch {
            logger.critical("Could not retrieve servers")
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
