//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

typealias MediaPlayerItemProviderResolver = @Sendable (BaseItemDto, (@Sendable (inout BaseItemDto) -> Void)?) async throws
    -> MediaPlayerItem

struct MediaPlayerItemProvider {

    let item: BaseItemDto
    let mediaSource: MediaSourceInfo?
    private var modifyItem: (@Sendable (inout BaseItemDto) -> Void)?
    private let resolver: MediaPlayerItemProviderResolver

    init(
        item: BaseItemDto,
        mediaSource: MediaSourceInfo? = nil,
        resolver: @escaping MediaPlayerItemProviderResolver
    ) {
        self.item = item
        self.mediaSource = mediaSource
        self.modifyItem = nil
        self.resolver = resolver
    }

    func modifyingItem(
        _ modifier: @escaping @Sendable (inout BaseItemDto) -> Void
    ) -> Self {
        var copy = self
        let currentModifier = modifyItem

        copy.modifyItem = { item in
            currentModifier?(&item)
            modifier(&item)
        }

        return copy
    }

    func callAsFunction() async throws -> MediaPlayerItem {
        try await resolver(item, modifyItem)
    }
}
