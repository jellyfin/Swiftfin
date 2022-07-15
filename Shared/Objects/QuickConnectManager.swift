//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

class QuickConnectManager {
	private var timer: Timer?
	private var secret: String?
	private var server: SwiftfinStore.State.Server

	private var authenticatedCallback: (_ secret: String) -> Void = { _ in }
	private var failureCallback: (_ error: String) -> Void = { _ in }

	var cancellables = Set<AnyCancellable>()

	init(server: SwiftfinStore.State.Server) {
		self.server = server
		JellyfinAPIAPI.basePath = self.server.currentURI
		AuthHeaderBuilder().setAuthHeader(accessToken: "")
	}

	func startQuickConnect(magicCodeCallback: @escaping (_ magic: String) -> Void,
	                       authenticatedCallback: @escaping (_ secret: String) -> Void,
	                       failureCallback: @escaping (_ error: String) -> Void)
	{
		self.authenticatedCallback = authenticatedCallback
		self.failureCallback = failureCallback

		LogManager.log.debug("Starting QuickConnect", tag: "QuickConnect")

		QuickConnectAPI.initiate()
			.sink(receiveCompletion: { completion in
				switch completion {
				case let .failure(error):
					self.failureCallback(error.localizedDescription)
				default:
					break
				}
			}, receiveValue: { response in

				guard let magicCode = response.code else {
					self.failureCallback("Error getting magic code")
					return
				}

				self.secret = response.secret
				magicCodeCallback(magicCode)
				LogManager.log.debug("Using QuickConnect magic code: \(magicCode)", tag: "QuickConnect")

				self.timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkAuthStatus), userInfo: nil,
				                                  repeats: true)
			})
			.store(in: &cancellables)
	}

	@objc
	private func checkAuthStatus() {
		guard let secret = self.secret else {
			LogManager.log.error("Wrong usage of QuickConnectManager", tag: "QuickConnect")
			return
		}

		QuickConnectAPI.connect(secret: secret)
			.sink(receiveCompletion: { completion in
				switch completion {
				case let .failure(error):
					LogManager.log.error("Error updating QuickConnect status: \(error)")
					self.failureCallback(error.localizedDescription)
					self.timer?.invalidate()
				default:
					break
				}
			}, receiveValue: { value in
				guard value.authenticated ?? false, let secret = self.secret else {
					LogManager.log.debug("QuickConnect Code not authenticated yet", tag: "QuickConnect")
					return
				}

				self.authenticatedCallback(secret)
			})
			.store(in: &cancellables)
	}
}
