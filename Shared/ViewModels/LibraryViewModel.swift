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
import SwiftUICollection

typealias LibraryRow = CollectionRow<Int, LibraryRowCell>

struct LibraryRowCell: Hashable {
  let id = UUID()
  let item: BaseItemDto?
  var loadingCell: Bool = false
}

final class LibraryViewModel: ViewModel {
    var parentID: String?
    var person: BaseItemPerson?
    var genre: NameGuidPair?
    var studio: NameGuidPair?

    @Published var items = [BaseItemDto]()
    @Published var rows = [LibraryRow]()

    @Published var totalPages = 0
    @Published var currentPage = 0
    @Published var hasNextPage = false
    @Published var hasPreviousPage = false

    // temp
    @Published var filters: LibraryFilters
  
    private let columns: Int

    var enabledFilterType: [FilterType] {
        if genre == nil {
            return [.tag, .genre, .sortBy, .sortOrder, .filter]
        } else {
            return [.tag, .sortBy, .sortOrder, .filter]
        }
    }

    init(
      parentID: String? = nil,
      person: BaseItemPerson? = nil,
      genre: NameGuidPair? = nil,
      studio: NameGuidPair? = nil,
      filters: LibraryFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], sortBy: [.name]),
      columns: Int = 7
    ) {
        self.parentID = parentID
        self.person = person
        self.genre = genre
        self.studio = studio
        self.filters = filters
        self.columns = columns
        super.init()

        $filters
            .sink(receiveValue: requestItems(with:))
            .store(in: &cancellables)
    }

    func requestItems(with filters: LibraryFilters) {
        let personIDs: [String] = [person].compactMap(\.?.id)
        let studioIDs: [String] = [studio].compactMap(\.?.id)
        let genreIDs: [String]
        if filters.withGenres.isEmpty {
            genreIDs = [genre].compactMap(\.?.id)
        } else {
            genreIDs = filters.withGenres.compactMap(\.id)
        }
        let sortBy = filters.sortBy.map(\.rawValue)
        let shouldBeRecursive: Bool = filters.filters.contains(.isFavorite) || personIDs != [] || studioIDs != [] || genreIDs != []
        ItemsAPI.getItemsByUserId(userId: SessionManager.main.currentLogin.user.id, startIndex: currentPage * 100, limit: 100, recursive: shouldBeRecursive,
                                  searchTerm: nil, sortOrder: filters.sortOrder, parentId: parentID,
                                  fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], includeItemTypes: filters.filters.contains(.isFavorite) ? ["Movie", "Series", "Season", "Episode"] : ["Movie", "Series"],
                                  filters: filters.filters, sortBy: sortBy, tags: filters.tags,
                                  enableUserData: true, personIds: personIDs, studioIds: studioIDs, genreIds: genreIDs, enableImages: true)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                LogManager.shared.log.debug("Received \(String(response.items?.count ?? 0)) items in library \(self?.parentID ?? "nil")")
                guard let self = self else { return }
                let totalPages = ceil(Double(response.totalRecordCount ?? 0) / 100.0)
                self.totalPages = Int(totalPages)
                self.hasPreviousPage = self.currentPage > 0
                self.hasNextPage = self.currentPage < self.totalPages - 1
                self.items = response.items ?? []
                self.rows = self.calculateRows()
            })
            .store(in: &cancellables)
    }

    func requestItemsAsync(with filters: LibraryFilters) {
        let personIDs: [String] = [person].compactMap(\.?.id)
        let studioIDs: [String] = [studio].compactMap(\.?.id)
        let genreIDs: [String]
        if filters.withGenres.isEmpty {
            genreIDs = [genre].compactMap(\.?.id)
        } else {
            genreIDs = filters.withGenres.compactMap(\.id)
        }
        let sortBy = filters.sortBy.map(\.rawValue)
        let shouldBeRecursive: Bool = filters.filters.contains(.isFavorite) || personIDs != [] || studioIDs != [] || genreIDs != []
        ItemsAPI.getItemsByUserId(userId: SessionManager.main.currentLogin.user.id, startIndex: currentPage * 100, limit: 100, recursive: shouldBeRecursive,
                                  searchTerm: nil, sortOrder: filters.sortOrder, parentId: parentID,
                                  fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], includeItemTypes: filters.filters.contains(.isFavorite) ? ["Movie", "Series", "Season", "Episode"] : ["Movie", "Series"],
                                  filters: filters.filters, sortBy: sortBy, tags: filters.tags,
                                  enableUserData: true, personIds: personIDs, studioIds: studioIDs, genreIds: genreIDs, enableImages: true)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                let totalPages = ceil(Double(response.totalRecordCount ?? 0) / 100.0)
                self.totalPages = Int(totalPages)
                self.hasPreviousPage = self.currentPage > 0
                self.hasNextPage = self.currentPage < self.totalPages - 1
                self.items.append(contentsOf: response.items ?? [])
                self.rows = self.calculateRows()
            })
            .store(in: &cancellables)
    }

    func requestNextPage() {
        currentPage += 1
        requestItems(with: filters)
    }

    func requestNextPageAsync() {
        currentPage += 1
        requestItemsAsync(with: filters)
    }

    func requestPreviousPage() {
        currentPage -= 1
        requestItems(with: filters)
    }
  
  private func calculateRows() -> [LibraryRow] {
    guard items.count > 0 else { return [] }
    let rowCount = items.count / columns
    var calculatedRows = [LibraryRow]()
    for i in (0...rowCount) {
      
      let firstItemIndex = i * columns
      var lastItemIndex = firstItemIndex + columns
      if lastItemIndex > items.count {
        lastItemIndex = items.count
      }
      
      var rowCells = [LibraryRowCell]()
      for item in items[firstItemIndex..<lastItemIndex] {
        let newCell = LibraryRowCell(item: item)
        rowCells.append(newCell)
      }
      if i == rowCount && hasNextPage {
        var loadingCell = LibraryRowCell(item: nil)
        loadingCell.loadingCell = true
        rowCells.append(loadingCell)
      }
      
      calculatedRows.append(
        LibraryRow(
          section: i,
          items: rowCells
        )
      )
    }
    
    return calculatedRows
  }
}
