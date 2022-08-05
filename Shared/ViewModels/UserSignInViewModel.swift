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
    private var Router: UserSignInCoordinator.Router?

    @Published
    var publicUsers: [UserDto] = []
    @Published
    var quickConnectCode: String?
    @Published
    var quickConnectEnabled = false

    let server: SwiftfinStore.State.Server
    private var quickConnectTimer: Timer?
    private var quickConnectSecret: String?

    init(server: SwiftfinStore.State.Server) {
        self.server = server
        super.init()

        JellyfinAPIAPI.basePath = server.currentURI
        checkQuickConnect()
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
        LogManager.log.debug("Attempting to login to server at \"\(server.currentURI)\"", tag: "login")

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

    func loadUsers() {
        UserAPI.getPublicUsers()
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(displayMessage: L10n.unableToConnectServer, completion: completion)
            }, receiveValue: { response in
                self.publicUsers = response
            })
            .store(in: &cancellables)
    }

    func getProfileImageUrl(user: UserDto) -> URL? {
        let urlString = ImageAPI.getUserImageWithRequestBuilder(
            userId: user.id ?? "--",
            imageType: .primary,
            width: 200,
            quality: 90
        ).URLString
        return URL(string: urlString)
    }

    func getSplashscreenUrl() -> URL? {
        let urlString = ImageAPI.getSplashscreenWithRequestBuilder().URLString
        return URL(string: urlString)
    }

    func checkQuickConnect() {
        QuickConnectAPI.getEnabled()
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(completion: completion)
            }, receiveValue: { enabled in
                self.quickConnectEnabled = enabled
                if enabled {
                    self.startQuickConnect()
                }
            })
            .store(in: &cancellables)
    }

    private func startQuickConnect() {
        QuickConnectAPI.initiate()
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(completion: completion)
            }, receiveValue: { response in

                self.quickConnectSecret = response.secret
                self.quickConnectCode = response.code
                LogManager.log.debug("QuickConnect code: \(response.code ?? "--")")

                self.quickConnectTimer = Timer.scheduledTimer(
                    timeInterval: 5,
                    target: self,
                    selector: #selector(self.checkAuthStatus),
                    userInfo: nil,
                    repeats: true
                )
            })
            .store(in: &cancellables)
    }

    @objc
    private func checkAuthStatus() {
        guard let quickConnectSecret = quickConnectSecret else { return }

        QuickConnectAPI.connect(secret: quickConnectSecret)
            .sink(receiveCompletion: { _ in
                // Prefer not to handle error handling like normal as
                // this is a repeated call
            }, receiveValue: { value in
                guard let authenticated = value.authenticated, authenticated else {
                    LogManager.log.debug("QuickConnect not authenticated yet")
                    return
                }

                self.quickConnectTimer?.invalidate()

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
}
