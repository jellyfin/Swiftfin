//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import CoreData
import Foundation
import JellyfinAPI

final class ServerEnvironment {
    static let shared = ServerEnvironment()
    fileprivate(set) var server: Server!

    init() {
        let serverRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Server")
        let servers = try? PersistenceController.shared.container.viewContext.fetch(serverRequest) as? [Server]
        server = servers?.first
        guard let baseURI = server?.baseURI else { return }
        JellyfinAPI.basePath = baseURI
    }

    func setUp(with uri: String) -> AnyPublisher<Server, Error> {
        var uri = uri
        if !uri.contains("http") {
            uri = "https://" + uri
        }
        if uri.last == "/" {
            uri = String(uri.dropLast())
        }
        JellyfinAPI.basePath = uri
        return SystemAPI.getPublicSystemInfo()
            .map { response in
                let server = Server(context: PersistenceController.shared.container.viewContext)
                server.baseURI = uri
                server.name = response.serverName
                server.server_id = response.id
                return server
            }
            .handleEvents(receiveOutput: { [unowned self] response in
                server = response
                _ = try? PersistenceController.shared.container.viewContext.save()
            }).eraseToAnyPublisher()
    }

    func reset() throws {
        JellyfinAPI.basePath = ""
        server = nil

        let serverRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Server")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: serverRequest)

        try PersistenceController.shared.container.viewContext.execute(deleteRequest)
    }
}
