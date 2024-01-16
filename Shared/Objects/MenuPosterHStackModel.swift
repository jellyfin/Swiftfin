//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import OrderedCollections

// TODO: Don't be specific to Poster, allow other types
// TODO: remove

protocol MenuPosterHStackModel: ObservableObject {
    associatedtype Section: Hashable, Displayable
    associatedtype Item: Poster

    var menuSelection: Section? { get }
    var menuSections: [Section: OrderedSet<Item>] { get set }
    var menuSectionSort: (Section, Section) -> Bool { get }

    func select(section: Section)
}
