//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import SwiftUI

class ServerListViewModel: ObservableObject {
    
    @Published var servers: [SwiftfinStore.State.Server] = []
    
    func fetchServers() {
        self.servers = SessionManager.main.fetchServers()
    }
    
    func userTextFor(server: SwiftfinStore.State.Server) -> String {
        if server.userIDs.count == 1 {
            return "1 user"
        } else {
            return "\(server.userIDs.count) users"
        }
    }
}
