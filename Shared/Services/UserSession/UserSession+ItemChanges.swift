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

@MainActor
extension UserSession {

    func observeItemChanges() {
        itemChanges = serverSocketManager.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self, self.itemChanges != nil, self.items.isActive,
                      case let .message(message) = event else { return }
                switch message {
                case let .userDataChangedMessage(message):
                    guard let data = message.data, data.userID == self.user.id else { return }
                    for data in data.userDataList {
                        do {
                            try self.items.mergeUserData(data, token: self.items.beginRequest())
                        } catch {}
                    }
                case let .libraryChangedMessage(message):
                    guard let data = message.data else { return }
                    self.items.libraryDidChange()
                    for id in data.itemsRemoved ?? [] {
                        self.items.delete(id: id)
                    }
                    for id in data.itemsUpdated ?? [] {
                        guard let record = self.items.retainedRecord(id: id) else { continue }
                        Task { @MainActor [weak self] in
                            guard let self, self.itemChanges != nil, let item = record.value else { return }
                            _ = try? await item.getFullItem(userSession: self)
                        }
                    }
                default:
                    break
                }
            }
    }
}
