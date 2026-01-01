//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@preconcurrency import JellyfinAPI

typealias MediaPlayerItemProviderFunction = @Sendable (BaseItemDto) async throws -> MediaPlayerItem

struct MediaPlayerItemProvider: Equatable, Sendable {

    let item: BaseItemDto
    let function: MediaPlayerItemProviderFunction

    static func == (lhs: MediaPlayerItemProvider, rhs: MediaPlayerItemProvider) -> Bool {
        false
    }

    func callAsFunction() async throws -> MediaPlayerItem {
        try await function(item)
    }
}
