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
    
    init() {
        // Workaround since Stinsen doesn't allow rebuilding the root even if it's the same active root
        let nc = SwiftfinNotificationCenter.main
        nc.addObserver(self, selector: #selector(didPurge), name: SwiftfinNotificationCenter.Keys.didPurge, object: nil)
    }
    
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
    
    func remove(server: SwiftfinStore.State.Server) {
        SessionManager.main.delete(server: server)
        fetchServers()
    }
    
    @objc private func didPurge() {
        fetchServers()
    }
}
