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

extension ItemStore: UserSessionService {

    func willStart(userSession: UserSession) async {
        subscriptions.removeAll()
        userSession.serverSocketManager.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak userSession] event in
                guard let self, let userSession, self.isActive, self.session === userSession,
                      case let .message(message) = event else { return }
                switch message {
                case let .userDataChangedMessage(message):
                    guard let data = message.data, data.userID == userSession.user.id else { return }
                    for data in data.userDataList {
                        do {
                            try self.mergeUserData(data, token: self.beginRequest())
                        } catch {
                            // Session shutdown or an invalid item cannot change another session.
                        }
                    }
                case let .libraryChangedMessage(message):
                    guard let data = message.data else { return }
                    for id in data.itemsRemoved ?? [] {
                        self.delete(id: id)
                    }
                    for id in data.itemsUpdated ?? [] {
                        guard let record = self.retainedRecord(id: id) else { continue }
                        Task { @MainActor [weak userSession] in
                            guard let userSession, let item = record.value else { return }
                            _ = try? await item.getFullItem(userSession: userSession)
                        }
                    }
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }

    func willStop(userSession: UserSession) {
        invalidate()
    }
}
