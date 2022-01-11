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

final class MovieItemViewModel: ItemViewModel {

	override func updateItem() {
		ItemsAPI.getItems(userId: SessionManager.main.currentLogin.user.id,
		                  limit: 1,
		                  fields: [
		                  	.primaryImageAspectRatio,
		                  	.seriesPrimaryImage,
		                  	.seasonUserData,
		                  	.overview,
		                  	.genres,
		                  	.people,
		                  	.chapters,
		                  ],
		                  enableUserData: true,
		                  ids: [item.id ?? ""])
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { response in
				if let item = response.items?.first {
					self.item = item
					self.playButtonItem = item
				}
			}
			.store(in: &cancellables)
	}
}
