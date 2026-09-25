//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

extension UserSessionManager {

    func observeLibraryChanges() {
        $currentSession
            .map { session -> AnyPublisher<LibraryUpdateInfo, Never> in
                session?.serverSocketManager.libraryUpdates ?? Combine.Empty<LibraryUpdateInfo, Never>()
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] update in
                Task { @MainActor in
                    self?.onReceive(libraryUpdate: update)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func onReceive(libraryUpdate: LibraryUpdateInfo) {
        for itemID in libraryUpdate.itemsUpdated ?? [] {
            Notifications[.itemShouldRefreshMetadata].post(itemID.dashedItemID)
        }
    }
}

private extension String {

    var dashedItemID: String {
        guard count == 32, allSatisfy(\.isHexDigit) else { return self }

        var id = self
        for offset in [20, 16, 12, 8] {
            id.insert("-", at: index(startIndex, offsetBy: offset))
        }
        return id
    }
}
