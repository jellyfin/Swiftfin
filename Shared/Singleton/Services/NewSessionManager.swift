//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreData
import CoreStore
import Defaults
import Factory
import Foundation
import JellyfinAPI
import UIKit

final class SwiftfinSession {
    
    let client: JellyfinClient
    let server: ServerState
    let user: UserState
    
    init(
        server: ServerState,
        user: UserState
    ) {
        self.server = server
        self.user = user
        
        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: server.currentURL),
            accessToken: user.accessToken
        )
        
        self.client = client
    }
}

final class BasicServerSession {
    
    let client: JellyfinClient
    let server: ServerState
    
    init(server: ServerState) {
        self.server = server
        
        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: server.currentURL)
        )
        
        self.client = client
    }
}

extension Container.Scope {
    static var basicServerSessionScope = Shared()
    static var userSessionScope = Cached()
}

extension Container {
    
    static let basicServerSessionScope = ParameterFactory<ServerState, BasicServerSession>(scope: .basicServerSessionScope) {
        .init(server: $0)
    }
    
    static let userSession = Factory<SwiftfinSession>(scope: .userSessionScope) {
        
        if let lastUserID = Defaults[.lastServerUserID],
           let user = try? SwiftfinStore.dataStack.fetchOne(
               From<SwiftfinStore.Models.StoredUser>(),
               [Where<SwiftfinStore.Models.StoredUser>("id == %@", lastUserID)]
           )
        {
            guard let server = user.server,
                  let existingServer = SwiftfinStore.dataStack.fetchExisting(server)
            else {
                // TODO: Log and return sample
                fatalError("No associated server for last user")
            }
            
            return .init(server: server.state, user: user.state)

        } else {
            return .init(server: .sample, user: .sample)
        }
    }
}

extension JellyfinClient.Configuration {
    
    static func swiftfinConfiguration(url: URL) -> Self {
        
        let client = "Swiftfin \(UIDevice.platform)"
        let deviceName = UIDevice.current.name
            .folding(options: .diacriticInsensitive, locale: .current)
            .unicodeScalars
            .filter({ CharacterSet.urlQueryAllowed.contains($0) })
            .description
        let deviceID = "\(UIDevice.platform)_\(UIDevice.vendorUUIDString)"
        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.1"
        
        return .init(
            url: url,
            client: client,
            deviceName: deviceName,
            deviceID: deviceID,
            version: version
        )
    }
}
