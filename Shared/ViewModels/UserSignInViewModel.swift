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
	var router: UserSignInCoordinator.Router?
	let server: SwiftfinStore.State.Server

	@Published
	var publicUsers: [UserDto] = []

	init(server: SwiftfinStore.State.Server) {
		self.server = server
		JellyfinAPIAPI.basePath = server.currentURI
	}

	var alertTitle: String {
		var message: String = ""
		if errorMessage?.code != ErrorMessage.noShowErrorCode {
			message.append(contentsOf: "\(errorMessage?.code ?? ErrorMessage.noShowErrorCode)\n")
		}
		message.append(contentsOf: "\(errorMessage?.title ?? L10n.unknownError)")
		return message
	}

	func login(username: String, password: String) {
		LogManager.log.debug("Attempting to login to server at \"\(server.currentURI)\"", tag: "login")

		SessionManager.main.loginUser(server: server, username: username, password: password)
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
		let urlString = ImageAPI.getUserImageWithRequestBuilder(userId: user.id ?? "--",
		                                                        imageType: .primary,
		                                                        width: 200,
		                                                        quality: 90).URLString
		return URL(string: urlString)
	}

	func getSplashscreenUrl() -> URL? {
		let urlString = ImageAPI.getSplashscreenWithRequestBuilder().URLString
		return URL(string: urlString)
	}
}
