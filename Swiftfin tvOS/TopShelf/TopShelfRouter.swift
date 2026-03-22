//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@MainActor
final class TopShelfRouter: ObservableObject {

    static let shared: TopShelfRouter = .init()

    @Published
    private(set) var pendingDeepLink: TopShelfDeepLink?

    private init() {}

    func receive(_ url: URL) {
        guard let deepLink = TopShelfDeepLink(url: url) else { return }
        pendingDeepLink = deepLink
    }

    func clear(_ deepLink: TopShelfDeepLink) {
        guard pendingDeepLink == deepLink else { return }
        pendingDeepLink = nil
    }
}
