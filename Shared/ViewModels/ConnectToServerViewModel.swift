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
    @Published
    var uri = ""
    @Published
    var username = ""
    @Published
    var password = ""

    @Published
    var lastPublicUsers = [UserDto]()
    @Published
    var publicUsers = [UserDto]()
    @Published
    var selectedPublicUser = UserDto()

    override init() {
        super.init()
        getPublicUsers()
    }

    func getPublicUsers() {
        if ServerEnvironment.current.server != nil {
            UserAPI.getPublicUsers()
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
        ServerEnvironment.current.create(with: uri)
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

    func login() {
        SessionManager.current.login(username: username, password: password)
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestCompletion(completion: completion)
            }, receiveValue: { _ in

            })
            .store(in: &cancellables)
    }
}
