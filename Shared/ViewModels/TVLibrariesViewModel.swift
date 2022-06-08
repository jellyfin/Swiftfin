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
import Stinsen
import SwiftUICollection

final class TVLibrariesViewModel: ViewModel {

	@Published
	var rows = [LibraryRow]()
	@Published
	var totalPages = 0
	@Published
	var currentPage = 0
	@Published
	var hasNextPage = false
	@Published
	var hasPreviousPage = false

	private var libraries = [BaseItemDto]()
	private let columns: Int

	@RouterObject
	var router: TVLibrariesCoordinator.Router?

	init(columns: Int = 7) {
		self.columns = columns
		super.init()

		requestLibraries()
	}

	func requestLibraries() {

		UserViewsAPI.getUserViews(userId: SessionManager.main.currentLogin.user.id)
			.trackActivity(loading)
			.sink(receiveCompletion: { completion in
				self.handleAPIRequestError(completion: completion)
			}, receiveValue: { response in
				if let responseItems = response.items {
					self.libraries = []
					for library in responseItems {
						if library.collectionType == "tvshows" {
							self.libraries.append(library)
						}
					}
					self.rows = self.calculateRows()
					if self.libraries.count == 1, let library = self.libraries.first {
						// make this library the root of this stack
						self.router?.coordinator.root(\.rootLibrary, library)
					}
				}
			})
			.store(in: &cancellables)
	}

	private func calculateRows() -> [LibraryRow] {
		guard !libraries.isEmpty else { return [] }
		let rowCount = libraries.count / columns
		var calculatedRows = [LibraryRow]()
		for i in 0 ... rowCount {
			let firstItemIndex = i * columns
			var lastItemIndex = firstItemIndex + columns
			if lastItemIndex > libraries.count {
				lastItemIndex = libraries.count
			}

			var rowCells = [LibraryRowCell]()
			for item in libraries[firstItemIndex ..< lastItemIndex] {
				let newCell = LibraryRowCell(item: item)
				rowCells.append(newCell)
			}
			if i == rowCount && hasNextPage {
				var loadingCell = LibraryRowCell(item: nil)
				loadingCell.loadingCell = true
				rowCells.append(loadingCell)
			}

			calculatedRows.append(LibraryRow(section: i,
			                                 items: rowCells))
		}
		return calculatedRows
	}
}
