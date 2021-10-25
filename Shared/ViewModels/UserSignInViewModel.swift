//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import CoreStore
import Foundation
import Stinsen

final class UserSignInViewModel: ViewModel {
    
    @RouterObject var router: UserSignInCoordinator.Router?
    let server: SwiftfinStore.State.Server
    
    init(server: SwiftfinStore.State.Server) {
        self.server = server
    }
    
    var alertTitle: String {
        var message: String = ""
        if errorMessage?.code != ErrorMessage.noShowErrorCode {
            message.append(contentsOf: "\(errorMessage?.code ?? ErrorMessage.noShowErrorCode)\n")
        }
        message.append(contentsOf: "\(errorMessage?.title ?? "Unkown Error")")
        return message
    }
    
    func login(username: String, password: String) {
        LogManager.shared.log.debug("Attempting to login to server at \"\(server.currentURI)\"", tag: "login")
        LogManager.shared.log.debug("username: \(username), password: \(password)", tag: "login")
        
        SessionManager.main.loginUser(server: server, username: username, password: password)
            .trackActivity(loading)
            .sink { completion in
                self.handleAPIRequestError(displayMessage: "Unable to connect to server.", logLevel: .critical, tag: "login",
                                           completion: completion)
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
}
