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

class UserListViewModel: ViewModel {
    
    @Published var users: [SwiftfinStore.State.User] = []
    
    let server: SwiftfinStore.State.Server
    
    init(server: SwiftfinStore.State.Server) {
        self.server = server
    }
    
    func fetchUsers() {
        self.users = SessionManager.main.fetchUsers(for: server)
    }
    
    func login(user: SwiftfinStore.State.User) {
        self.isLoading = true
        SessionManager.main.loginUser(server: server, user: user)
    }
    
    func remove(user: SwiftfinStore.State.User) {
        SessionManager.main.delete(user: user)
        fetchUsers()
    }
}
