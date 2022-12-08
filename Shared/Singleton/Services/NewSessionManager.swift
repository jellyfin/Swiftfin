//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreData
import CoreStore
import Factory
import Foundation
import JellyfinAPI

final class SwiftfinSession {
    
    let client: JellyfinClient
    let server: SwiftfinStore.State.Server
}

final class NewSessionManager {
    
    
    
}

extension Container.Scope {
    static var userSessionScope = Cached()
}

extension Container {
    
    static let userSession = Factory(scope: .userSessionScope) {
        
    }
}
