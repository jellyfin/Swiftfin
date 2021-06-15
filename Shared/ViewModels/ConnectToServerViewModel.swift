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
    var publicUsers = [UserDto]()
    @Published
    var isConnectedServer = false
    @Published
    var isLoggedIn = false
    @Published
    var uri = ""
    @Published
    var username = ""
    @Published
    var password = ""
    

    override init() {
        super.init()

        refresh()
    }

    func refresh() {
        if ServerEnvironment.current.server != nil {
            UserAPI.getPublicUsers()
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        self.isConnectedServer = false
                    }
                }, receiveValue: { response in
                    self.publicUsers = response
                    self.isConnectedServer = true
                })
                .store(in: &cancellables)
        }
    }
    
    func connectToServer() {
        ServerEnvironment.current.setUp(with: uri)
            .sink(receiveCompletion: { result in
                switch result {
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                default:
                    break
                }
            }, receiveValue: { response in
                guard response.server_id != nil else {
                    return
                }
                self.isConnectedServer = true
            })
            .store(in: &cancellables)
    }

    func login() {
        SessionManager.current.login(username: username, password: password)
            .sink(receiveCompletion: { result in
                switch result {
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                default:
                    break
                }
            }, receiveValue: { response in
                guard response.user_id != nil else {
                    return
                }
                self.isLoggedIn = true
            })
            .store(in: &cancellables)
    }
}
