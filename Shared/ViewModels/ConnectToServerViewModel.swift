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
    @Published
    var isConnectedServer = false

    var uriSubject = CurrentValueSubject<String, Never>("")
    var usernameSubject = CurrentValueSubject<String, Never>("")
    var passwordSubject = CurrentValueSubject<String, Never>("")

    @Published
    var lastPublicUsers = [UserDto]()
    @Published
    var publicUsers = [UserDto]()
    @Published
    var selectedPublicUser = UserDto()

    private let discovery: ServerDiscovery = ServerDiscovery()
    @Published var servers: [ServerDiscovery.ServerLookupResponse] = []
    @Published var searching = false

    override init() {
        super.init()
        getPublicUsers()
    }

    func getPublicUsers() {
        if ServerEnvironment.current.server != nil {
            UserAPI.getPublicUsers()
                .trackActivity(loading)
                .sink(receiveCompletion: { completion in
                    self.handleAPIRequestCompletion(completion: completion)
                }, receiveValue: { response in
                    self.publicUsers = response
                    self.isConnectedServer = true
                })
                .store(in: &cancellables)
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
        ServerEnvironment.current.create(with: uriSubject.value)
            .trackActivity(loading)
            .sink(receiveCompletion: { result in
                switch result {
                    case let .failure(error):
                        self.errorMessage = error.localizedDescription
                    default:
                        break
                }
            }, receiveValue: { _ in
                self.getPublicUsers()
            })
            .store(in: &cancellables)
    }

    func connectToServer(at url: URL) {
        ServerEnvironment.current.create(with: url.absoluteString)
            .trackActivity(loading)
            .sink(receiveCompletion: { result in
                switch result {
                    case let .failure(error):
                        self.errorMessage = error.localizedDescription
                    default:
                        break
                }
            }, receiveValue: { _ in
                self.getPublicUsers()
            })
            .store(in: &cancellables)
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
        SessionManager.current.login(username: usernameSubject.value, password: passwordSubject.value)
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        if let err = error as? ErrorResponse {
                            switch err {
                                case .error(401, _, _, _):
                                    self.errorMessage = "Invalid credentials"
                                case .error:
                                    self.errorMessage = err.localizedDescription
                            }
                        }
                        break
                }
            }, receiveValue: { _ in

            })
            .store(in: &cancellables)
    }
}
