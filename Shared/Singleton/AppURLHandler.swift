//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import Stinsen

final class AppURLHandler {
    static let deepLinkScheme = "jellyfin"

    @RouterObject
    var router: HomeCoordinator.Router?

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
            if launchURL == nil {
                return processURL(url)
            }
        } else {
            launchURL = url
        }
        return true
    }

    func processLaunchedURLIfNeeded() {
        guard let launchURL = launchURL else { return }
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
           let itemID = url.pathComponents[safe: 3]
        {
//            router?.route(to: \.item(item: item))
            return true
        }

        return false
    }
}
