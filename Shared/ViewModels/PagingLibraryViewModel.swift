//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Get
import JellyfinAPI
import OrderedCollections
import UIKit

class PagingLibraryViewModel: ViewModel {

    static let DefaultPageSize = 16

    @Published
    final var items: OrderedSet<BaseItemDto>

    private var currentPage = 0
    private var hasNextPage = true
    private var currentPagingRequest: AnyCancellable? {
        didSet {
            print("did set currentPagingRequest")
        }
    }

    deinit {
        print("PagingLibraryViewModel.deinit")
    }

    override init() {
        self.items = []
    }

    init(_ data: some Collection<BaseItemDto>) {
        items = OrderedSet(data)
        currentPage = data.count / Self.DefaultPageSize
    }

    // TODO: move out
    func getRandomItem() async -> BaseItemDto? {
        nil
//        var parameters = _getDefaultParams()
//        parameters?.limit = 1
//        parameters?.sortBy = [SortBy.random.rawValue]
//
//        await MainActor.run {
//            self.isLoading = true
//        }
//
//        let request = Paths.getItems(parameters: parameters)
//        let response = try? await userSession.client.send(request)
//
//        await MainActor.run {
//            self.isLoading = false
//        }
//
//        return response?.value.items?.first
    }

    final func refresh() async throws {

        currentPage = -1
        hasNextPage = true

        await MainActor.run {
            items = []
        }

        let a = Task {
            try await getNextPage()
        }

        currentPagingRequest = a.asAnyCancellable()

        try await a.value
    }

    /// Gets the next page of items or immediately returns if
    /// there is not a next page.
    ///
    /// See `get(page:)` for the conditions that determine
    /// if there is a next page or not.
    final func getNextPage() async throws {
        guard !isLoading, hasNextPage else { return }

        await MainActor.run {
            isLoading = true
        }

        currentPage += 1

        try await Task.sleep(nanoseconds: 10_000_000_000)
        let pageItems = try await get(page: currentPage)

        hasNextPage = !(pageItems.count < Self.DefaultPageSize)

        await MainActor.run {
            items.append(contentsOf: pageItems)
            isLoading = false
        }
    }

    /// Gets the items at the given page. If the number of items
    /// is less than `DefaultPageSize`, then it is inferred that
    /// there is not a next page and subsequent calls to `getNextPage`
    /// will immediately return.
    func get(page: Int) async throws -> [BaseItemDto] {
        []
    }
}
