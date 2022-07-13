//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class QuickConnectSettingsViewModel: ViewModel {

	@Published
	var quickConnectCode = ""
	@Published
	var showSuccessMessage = false

	var alertTitle: String {
		var message: String = ""
		if errorMessage?.code != ErrorMessage.noShowErrorCode {
			message.append(contentsOf: "\(errorMessage?.code ?? ErrorMessage.noShowErrorCode)\n")
		}
		message.append(contentsOf: "\(errorMessage?.title ?? L10n.unknownError)")
		return message
	}

	func sendQuickConnect() {
		QuickConnectAPI.authorize(code: self.quickConnectCode)
			.trackActivity(loading)
			.sink(receiveCompletion: { completion in
				self.handleAPIRequestError(displayMessage: L10n.quickConnectInvalidError, completion: completion)
				switch completion {
				case .failure:
					LogManager.log.debug("Invalid Quick Connect code entered")
				default:
					break
				}
			}, receiveValue: { _ in
				// receiving a successful HTTP response indicates a valid code
				LogManager.log.debug("Valid Quick connect code entered")
				self.showSuccessMessage = true
			})
			.store(in: &cancellables)
	}
}
