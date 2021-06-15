//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import Combine
import Nuke
import WidgetKit

final class SplashViewModel: ViewModel {
 
    @Published
    var isLoggedIn: Bool
    
    override init() {
        isLoggedIn = ServerEnvironment.current.server != nil && SessionManager.current.user != nil
        super.init()
        
        ImageCache.shared.costLimit = 125 * 1024 * 1024 // 125MB memory
        DataLoader.sharedUrlCache.diskCapacity = 1000 * 1024 * 1024 // 1000MB disk
        
        WidgetCenter.shared.reloadAllTimelines()
        
        let defaults = UserDefaults.standard
        if defaults.integer(forKey: "InNetworkBandwidth") == 0 {
            defaults.setValue(40_000_000, forKey: "InNetworkBandwidth")
        }
        if defaults.integer(forKey: "OutOfNetworkBandwidth") == 0 {
            defaults.setValue(40_000_000, forKey: "OutOfNetworkBandwidth")
        }
    }
}
