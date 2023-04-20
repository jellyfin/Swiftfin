//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Files
import Foundation
import UIKit

final class SettingsViewModel: ViewModel {

    @Published
    var currentAppIcon: any AppIcon = PrimaryAppIcon.primary

    override init() {

        guard let iconName = UIApplication.shared.alternateIconName else {
            currentAppIcon = PrimaryAppIcon.primary
            super.init()
            return
        }

        if let appicon = PrimaryAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
            super.init()
            return
        }

        if let appicon = DarkAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
            super.init()
            return
        }

        if let appicon = InvertedDarkAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
            super.init()
            return
        }

        if let appicon = InvertedLightAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
            super.init()
            return
        }

        if let appicon = LightAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
            super.init()
            return
        }

        super.init()
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

    func signOut() {
        Defaults[.lastServerUserID] = nil
        Container.userSession.reset()
        Notifications[.didSignOut].post()
    }

    func resetUserSettings() {
        UserDefaults.generalSuite.removeAll()
    }

    func removeAllServers() {
        guard let allServers = try? SwiftfinStore.dataStack.fetchAll(From<ServerModel>()) else { return }

        try? SwiftfinStore.dataStack.perform { transaction in
            transaction.delete(allServers)
        }
    }
}
