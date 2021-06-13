//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import CoreData

final class ServerEnvironment {
    
    static let shared = ServerEnvironment()
    var server: Server?
    
    init() {
        let serverRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Server")
        let servers = try? PersistenceController.shared.container.viewContext.fetch(serverRequest) as? [Server]
        server = servers?.first
    }
}
