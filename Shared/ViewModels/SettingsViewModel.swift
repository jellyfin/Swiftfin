//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

final class SettingsViewModel: ViewModel {

    @Published
    var currentAppIcon: any AppIcon
    
    let server: SwiftfinStore.State.Server
    let user: SwiftfinStore.State.User

    init(server: SwiftfinStore.State.Server, user: SwiftfinStore.State.User) {
        self.server = server
        self.user = user
        
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
        
        if let appicon = InverseAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
            super.init()
            return
        }
        
        if let appicon = LightAppIcon.createCase(iconName: iconName) {
            currentAppIcon = appicon
            super.init()
            return
        }
        
        currentAppIcon = PrimaryAppIcon.primary
        
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
}
