//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

enum ItemRefreshType {
    /// Refresh this Item's Metadata
    case metadata
    /// Refresh this Item's UserData
    case userData
    /// Refresh the Metadata for all children of this Item
    case childMetadata
    /// Refresh the UserData for all children of this Item
    case childUserData
}
