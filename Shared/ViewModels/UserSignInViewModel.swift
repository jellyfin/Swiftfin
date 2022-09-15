//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import JellyfinAPI
import Stinsen

final class UserSignInViewModel: ViewModel {

    @RouterObject
    private var router: UserSignInCoordinator.Router?

    @Published
    var publicUsers: [UserDto] = []
    @Published
    var quickConnectCode: String?
    @Published
    var quickConnectEnabled = false

    let server: SwiftfinStore.State.Server
    private var quickConnectTimer: RepeatingTimer?
    private var quickConnectSecret: String?

    init(server: SwiftfinStore.State.Server) {
        self.server = server
        super.init()

        JellyfinAPIAPI.basePath = server.currentURI
        checkQuickConnect()
        getPublicUsers()
    }

    var alertTitle: String {
        var message: String = ""
        if errorMessage?.code != ErrorMessage.noShowErrorCode {
            message.append(contentsOf: "\(errorMessage?.code ?? ErrorMessage.noShowErrorCode)\n")
        }
        message.append(contentsOf: "\(errorMessage?.title ?? L10n.unknownError)")
        return message
    }

    func signIn(username: String, password: String) {
        logger.debug("Attempting to login to server at \"\(server.currentURI)\"", tag: "login")

        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        SessionManager.main.signInUser(server: server, username: username, password: password)
            .trackActivity(loading)
            .sink { completion in
                self.handleAPIRequestError(displayMessage: L10n.unableToConnectServer, completion: completion)
            } receiveValue: { _ in
            }
            .store(in: &cancellables)
    }

    func cancelSignIn() {
        for cancellable in cancellables {
            cancellable.cancel()
        }

        self.isLoading = false
    }

    func getPublicUsers() {
        UserAPI.getPublicUsers()
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(displayMessage: L10n.unableToConnectServer, completion: completion)
            }, receiveValue: { response in
                self.publicUsers = response
            })
            .store(in: &cancellables)
    }

    func checkQuickConnect() {
        QuickConnectAPI.getEnabled()
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(completion: completion)
            }, receiveValue: { enabled in
                self.quickConnectEnabled = enabled
            })
            .store(in: &cancellables)
    }

    func startQuickConnect(_ onSuccess: @escaping () -> Void) {
        QuickConnectAPI.initiate()
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(completion: completion)
            }, receiveValue: { response in

                self.quickConnectSecret = response.secret
                self.quickConnectCode = response.code
                self.logger.debug("QuickConnect code: \(response.code ?? .emptyDash)")

                self.quickConnectTimer = RepeatingTimer(interval: 5) {
                    self.checkAuthStatus(onSuccess)
                }

                self.quickConnectTimer?.start()
            })
            .store(in: &cancellables)
    }

    @objc
    private func checkAuthStatus(_ onSuccess: @escaping () -> Void) {
        guard let quickConnectSecret = quickConnectSecret else { return }

        QuickConnectAPI.connect(secret: quickConnectSecret)
            .sink(receiveCompletion: { _ in
                // Prefer not to handle error handling like normal as
                // this is a repeated call
            }, receiveValue: { value in
                guard let authenticated = value.authenticated, authenticated else {
                    self.logger.debug("QuickConnect not authenticated yet")
                    return
                }

                self.stopQuickConnectAuthCheck()
                onSuccess()

                SessionManager.main.signInUser(server: self.server, quickConnectSecret: quickConnectSecret)
                    .trackActivity(self.loading)
                    .sink { completion in
                        self.handleAPIRequestError(displayMessage: L10n.unableToConnectServer, completion: completion)
                    } receiveValue: { _ in
                    }
                    .store(in: &self.cancellables)
            })
            .store(in: &cancellables)
    }

    func stopQuickConnectAuthCheck() {
        DispatchQueue.main.async {
            self.quickConnectTimer?.stop()
            self.quickConnectTimer = nil
        }
    }
}
