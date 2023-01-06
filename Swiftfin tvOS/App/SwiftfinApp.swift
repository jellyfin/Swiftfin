//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import UIKit

@main
struct SwiftfinApp: App {
    
    init() {
        Task {
            for await newValue in Defaults.updates(.appAppearance) {
//                Self.setupAppearance(with: newValue.style)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainCoordinator().view()
        }
    }
    
    private static func setupAppearance(with appearance: UIUserInterfaceStyle) {
        UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = appearance
    }
}
