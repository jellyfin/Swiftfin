//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// TODO: Extension declares a conformance of imported type 'ParentalRating' to imported protocol 'Identifiable'; this will not behave correctly if the owners of 'JellyfinAPI' introduce this conformance in the future
extension ParentalRating: Identifiable {
    public var id: String {
        name ?? UUID().uuidString
    }
}

// TODO: Conformance of 'ParentalRating' to protocol 'Equatable' was already stated in the type's module 'JellyfinAPI'
extension ParentalRating: Equatable {
    public static func == (lhs: ParentalRating, rhs: ParentalRating) -> Bool {
        lhs.name == rhs.name && lhs.value == rhs.value
    }
}
