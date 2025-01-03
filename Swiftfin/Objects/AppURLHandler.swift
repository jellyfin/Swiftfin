//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Stinsen

final class AppURLHandler {
    static let deepLinkScheme = "jellyfin"

    enum AppURLState {
        case launched
        case allowedInLogin
        case allowed

        func allowedScheme(with url: URL) -> Bool {
            switch self {
            case .launched:
                return false
            case .allowed:
                return true
            case .allowedInLogin:
                return false
            }
        }
    }

    static let shared = AppURLHandler()

    var cancellables = Set<AnyCancellable>()

    var appURLState: AppURLState = .launched
    var launchURL: URL?
}

extension AppURLHandler {
    @discardableResult
    func processDeepLink(url: URL) -> Bool {
        guard url.scheme == Self.deepLinkScheme || url.scheme == "widget-extension" else {
            return false
        }
        if AppURLHandler.shared.appURLState.allowedScheme(with: url) {
            return processURL(url)
        } else {
            launchURL = url
        }
        return true
    }

    func processLaunchedURLIfNeeded() {
        guard let launchURL = launchURL,
              launchURL.absoluteString.isNotEmpty else { return }
        if processDeepLink(url: launchURL) {
            self.launchURL = nil
        }
    }

    private func processURL(_ url: URL) -> Bool {
        if processURLForUser(url: url) {
            return true
        }

        return false
    }

    private func processURLForUser(url: URL) -> Bool {
        guard url.host?.lowercased() == "users",
              url.pathComponents[safe: 1]?.isEmpty == false else { return false }

        // /Users/{UserID}/Items/{ItemID}
        if url.pathComponents[safe: 2]?.lowercased() == "items",
           let userID = url.pathComponents[safe: 1],
           let itemID = url.pathComponents[safe: 3]
        {
            // It would be nice if the ItemViewModel could be initialized to id later.
            getItem(userID: userID, itemID: itemID) { item in
                guard let item = item else { return }
                // TODO: reimplement URL handling
//                Notifications[.processDeepLink].post(DeepLink.item(item))
            }

            return true
        }

        return false
    }
}

extension AppURLHandler {
    func getItem(userID: String, itemID: String, completion: @escaping (BaseItemDto?) -> Void) {
//        UserLibraryAPI.getItem(userId: userID, itemId: itemID)
//            .sink(receiveCompletion: { innerCompletion in
//                switch innerCompletion {
//                case .failure:
//                    completion(nil)
//                default:
//                    break
//                }
//            }, receiveValue: { item in
//                completion(item)
//            })
//            .store(in: &cancellables)
    }
}
