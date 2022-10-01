//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

protocol MenuPosterHStackModel: ObservableObject {
    associatedtype Section: Hashable, Displayable
    associatedtype Item: Poster

    var selection: Section? { get }
    var sections: [Section: PosterHStackState<Item>] { get set }
    var sectionMenuSort: (Section, Section) -> Bool { get }

    func select(section: Section)
}
