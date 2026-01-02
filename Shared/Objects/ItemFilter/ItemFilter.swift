//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

protocol ItemFilter: Displayable {

    var value: String { get }

    // TODO: Should this be optional if the concrete type
    //       can't be constructed?
    init(from anyFilter: AnyItemFilter)
}

extension ItemFilter {

    var asAnyItemFilter: AnyItemFilter {
        .init(displayTitle: displayTitle, value: value)
    }
}

extension ItemFilter where Self: RawRepresentable<String> {

    var value: String {
        rawValue
    }

    init(from anyFilter: AnyItemFilter) {
        self.init(rawValue: anyFilter.value)!
    }
}

extension Array where Element: ItemFilter {

    var asAnyItemFilter: [AnyItemFilter] {
        map(\.asAnyItemFilter)
    }
}
