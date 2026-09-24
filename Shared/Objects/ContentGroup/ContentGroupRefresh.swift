//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum ContentGroupRefresh {
    /// Refresh the requesting group's view model, or all groups when sent by a provider.
    case contents
    /// Ask the provider to make a new set of groups.
    case groups
    /// Recheck visibility after contents have already changed, without fetching them again.
    case resolution
}

/// Requests are taken before awaiting work, leaving changes received in flight for the next pass.
struct ContentGroupRefreshQueue {
    private(set) var groupIDs: Set<String> = []
    private(set) var refreshAll = false
    private(set) var rebuildGroups = false
    private(set) var needsResolution = false

    var isEmpty: Bool {
        groupIDs.isEmpty && !refreshAll && !rebuildGroups && !needsResolution
    }

    mutating func insert(_ request: ContentGroupRefresh, groupID: String? = nil) {
        switch request {
        case .contents:
            if let groupID {
                groupIDs.insert(groupID)
            } else {
                refreshAll = true
            }
        case .groups:
            rebuildGroups = true
        case .resolution:
            needsResolution = true
        }
    }

    mutating func take() -> Self {
        let pending = self
        self = .init()
        return pending
    }

    mutating func merge(_ other: Self) {
        groupIDs.formUnion(other.groupIDs)
        refreshAll = refreshAll || other.refreshAll
        rebuildGroups = rebuildGroups || other.rebuildGroups
        needsResolution = needsResolution || other.needsResolution
    }
}
