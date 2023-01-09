//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

class SpecialFeaturesViewModel: ViewModel, MenuPosterHStackModel {

    @Published
    var menuSelection: SpecialFeatureType?
    @Published
    var menuSections: [SpecialFeatureType: [PosterButtonType<BaseItemDto>]]
    var menuSectionSort: (SpecialFeatureType, SpecialFeatureType) -> Bool

    init(sections: [SpecialFeatureType: [PosterButtonType<BaseItemDto>]]) {
        let comparator: (SpecialFeatureType, SpecialFeatureType) -> Bool = { i, j in i.rawValue < j.rawValue }
        self.menuSelection = Array(sections.keys).sorted(by: comparator).first!
        self.menuSections = sections
        self.menuSectionSort = comparator
    }

    func select(section: SpecialFeatureType) {
        self.menuSelection = section
    }
}
