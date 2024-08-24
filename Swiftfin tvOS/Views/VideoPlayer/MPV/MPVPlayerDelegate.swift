//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

@MainActor
public protocol MPVPlayerDelegate: AnyObject {
    func propertyChange(mpv: OpaquePointer, propertyName: String, data: Any?)
}
