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
import SwiftUICollection
import UIKit

typealias LibraryRow = CollectionRow<Int, LibraryRowCell>

struct LibraryRowCell: Hashable {
	let id = UUID()
	let item: BaseItemDto?
	var loadingCell: Bool = false
}

final class LibraryViewModel: ViewModel {

	@Published
	var items: [BaseItemDto] = []
	@Published
	var rows: [LibraryRow] = []

	@Published
	var totalPages = 0
	@Published
	var currentPage = 0
	@Published
	var hasNextPage = false

	// temp
	@Published
	var filters: LibraryFilters

	var parentID: String?
	var person: BaseItemPerson?
	var genre: NameGuidPair?
	var studio: NameGuidPair?
	private let columns: Int
	private let pageItemSize: Int

	var enabledFilterType: [FilterType] {
		if genre == nil {
			return [.tag, .genre, .sortBy, .sortOrder, .filter]
		} else {
			return [.tag, .sortBy, .sortOrder, .filter]
		}
	}

	init(parentID: String? = nil,
	     person: BaseItemPerson? = nil,
	     genre: NameGuidPair? = nil,
	     studio: NameGuidPair? = nil,
	     filters: LibraryFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], sortBy: [.name]),
	     columns: Int = 7)
	{
		self.parentID = parentID
		self.person = person
		self.genre = genre
		self.studio = studio
		self.filters = filters
		self.columns = columns

		// Size is typical size of portrait items
		self.pageItemSize = UIScreen.itemsFillableOnScreen(width: 130, height: 185)

		super.init()

		$filters
			.sink(receiveValue: { newFilters in
				self.requestItemsAsync(with: newFilters, replaceCurrentItems: true)
			})
			.store(in: &cancellables)
	}

	func requestItemsAsync(with filters: LibraryFilters, replaceCurrentItems: Bool = false) {

		if replaceCurrentItems {
			self.items = []
		}

		let personIDs: [String] = [person].compactMap(\.?.id)
		let studioIDs: [String] = [studio].compactMap(\.?.id)
		let genreIDs: [String]
		if filters.withGenres.isEmpty {
			genreIDs = [genre].compactMap(\.?.id)
		} else {
			genreIDs = filters.withGenres.compactMap(\.id)
		}
		let sortBy = filters.sortBy.map(\.rawValue)
		let queryRecursive = filters.filters.contains(.isFavorite) ||
			self.person != nil ||
			self.genre != nil ||
			self.studio != nil

		ItemsAPI.getItemsByUserId(userId: SessionManager.main.currentLogin.user.id, startIndex: currentPage * pageItemSize,
		                          limit: pageItemSize,
		                          recursive: queryRecursive,
		                          searchTerm: nil,
		                          sortOrder: filters.sortOrder,
		                          parentId: parentID,
		                          fields: [
		                          	.primaryImageAspectRatio,
		                          	.seriesPrimaryImage,
		                          	.seasonUserData,
		                          	.overview,
		                          	.genres,
		                          	.people,
		                          	.chapters,
		                          ],
		                          includeItemTypes: filters.filters
		                          	.contains(.isFavorite) ? ["Movie", "Series", "Season", "Episode", "BoxSet"] :
		                          	["Movie", "Series", "BoxSet", "Folder"],
		                          filters: filters.filters,
		                          sortBy: sortBy,
		                          tags: filters.tags,
		                          enableUserData: true,
		                          personIds: personIDs,
		                          studioIds: studioIDs,
		                          genreIds: genreIDs,
		                          enableImages: true)
			.trackActivity(loading)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in

				guard let self = self else { return }
				let totalPages = ceil(Double(response.totalRecordCount ?? 0) / Double(self.pageItemSize))

				self.totalPages = Int(totalPages)
				self.hasNextPage = self.currentPage < self.totalPages - 1
				self.items.append(contentsOf: response.items ?? [])
				self.rows = self.calculateRows(for: self.items)
			})
			.store(in: &cancellables)
	}

	func requestNextPageAsync() {
		currentPage += 1
		requestItemsAsync(with: filters)
	}

	// tvOS calculations for collection view
	private func calculateRows(for itemList: [BaseItemDto]) -> [LibraryRow] {
		guard !itemList.isEmpty else { return [] }
		let rowCount = itemList.count / columns
		var calculatedRows = [LibraryRow]()
		for i in 0 ... rowCount {
			let firstItemIndex = i * columns
			var lastItemIndex = firstItemIndex + columns
			if lastItemIndex > itemList.count {
				lastItemIndex = itemList.count
			}

			var rowCells = [LibraryRowCell]()
			for item in itemList[firstItemIndex ..< lastItemIndex] {
				let newCell = LibraryRowCell(item: item)
				rowCells.append(newCell)
			}
			if i == rowCount, hasNextPage {
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

extension UIScreen {

	static func itemsFillableOnScreen(width: CGFloat, height: CGFloat) -> Int {

		let screenSize = UIScreen.main.bounds.height * UIScreen.main.bounds.width
		let itemSize = width * height

		return Int(screenSize / itemSize)
	}
}
