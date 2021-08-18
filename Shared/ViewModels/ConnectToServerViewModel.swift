//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import Foundation
import JellyfinAPI

final class ConnectToServerViewModel: ViewModel {

    @Published var isConnectedServer = false

    var uriSubject = CurrentValueSubject<String, Never>("")
    var usernameSubject = CurrentValueSubject<String, Never>("")
    var passwordSubject = CurrentValueSubject<String, Never>("")

    @Published var lastPublicUsers = [UserDto]()
    @Published var publicUsers = [UserDto]()
    @Published var selectedPublicUser = UserDto()

    private let discovery: ServerDiscovery = ServerDiscovery()
    @Published var servers: [ServerDiscovery.ServerLookupResponse] = []
    @Published var searching = false

    func getPublicUsers() {
        if ServerEnvironment.current.server != nil {
            LogManager.shared.log.debug("Attempting to read public users from \(ServerEnvironment.current.server.baseURI!)", tag: "getPublicUsers")
            UserAPI.getPublicUsers()
                .trackActivity(loading)
                .sink(receiveCompletion: { completion in
                    self.handleAPIRequestError(completion: completion)
                }, receiveValue: { response in
                    self.publicUsers = response
                    LogManager.shared.log.debug("Received \(String(response.count)) public users.", tag: "getPublicUsers")
                    self.isConnectedServer = true
                })
                .store(in: &cancellables)
        } else {
            LogManager.shared.log.debug("Not getting users - server is nil", tag: "getPublicUsers")
        }
    }

    func hidePublicUsers() {
        self.lastPublicUsers = publicUsers
        publicUsers = []
    }

    func showPublicUsers() {
        self.publicUsers = lastPublicUsers
        lastPublicUsers = []
    }

    func connectToServer() {
        LogManager.shared.log.debug("Attempting to connect to server at \"\(uriSubject.value)\"", tag: "connectToServer")
        ServerEnvironment.current.create(with: uriSubject.value)
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(displayMessage: "Unable to connect to server.", logLevel: .critical, tag: "connectToServer", completion: completion)
            }, receiveValue: { _ in
                LogManager.shared.log.debug("Connected to server at \"\(self.uriSubject.value)\"", tag: "connectToServer")
                self.getPublicUsers()
            })
            .store(in: &cancellables)
    }

    func connectToServer(at url: URL) {
        uriSubject.send(url.absoluteString)
        self.connectToServer()
    }

    func discoverServers() {
        searching = true

        // Timeout after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.searching = false
        }

        discovery.locateServer { [self] (server) in
            if let server = server, !servers.contains(server) {
                servers.append(server)
            }
            searching = false
        }
    }

    func login() {
        LogManager.shared.log.debug("Attempting to login to server at \"\(uriSubject.value)\"", tag: "login")
        LogManager.shared.log.debug("username == \"\": \(usernameSubject.value.isEmpty), password == \"\": \(passwordSubject.value.isEmpty)", tag: "login")
        SessionManager.current.login(username: usernameSubject.value, password: passwordSubject.value)
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(displayMessage: "Unable to connect to server.", logLevel: .critical, tag: "login", completion: completion)
            }, receiveValue: { _ in

            })
            .store(in: &cancellables)
    }
}
