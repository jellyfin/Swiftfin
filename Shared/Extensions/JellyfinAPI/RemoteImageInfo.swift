//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

/// Extension declares a conformance of imported type 'RemoteImageInfo' to imported protocol 'Identifiable'; this will not behave correctly
/// if the owners of 'JellyfinAPI' introduce this conformance in the future
extension RemoteImageInfo: Identifiable {

    public var id: String {
        UUID().uuidString
    }
}
