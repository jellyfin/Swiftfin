//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import Get
import JellyfinAPI
import OrderedCollections
import UIKit

class PagingLibraryViewModel: ViewModel {

    /// The default page
    static let DefaultPageSize = 50

    @Published
    var items: OrderedSet<BaseItemDto>

    var currentPage = 0
    var hasNextPage = true

    override init() {
        self.items = []
    }

    init(_ data: some Collection<BaseItemDto>) {
        items = OrderedSet(data)
        currentPage = data.count / Self.DefaultPageSize
    }

    public func getRandomItemFromLibrary() async throws -> BaseItemDtoQueryResult {

        var parameters = _getDefaultParams()
        parameters?.limit = 1
        parameters?.sortBy = [SortBy.random.rawValue]

        await MainActor.run {
            self.isLoading = true
        }

        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.isLoading = false
        }

        return response.value
    }

    func _getDefaultParams() -> Paths.GetItemsParameters? {
        Paths.GetItemsParameters()
    }

    func refresh() async {
        currentPage = 0
        hasNextPage = true

        await MainActor.run {
            items = []
        }

        _requestNextPage()
    }

    func requestNextPage() {
        guard hasNextPage else { return }
        currentPage += 1
        _requestNextPage()
    }

    func _requestNextPage() {}
}
