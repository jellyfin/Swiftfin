//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import Foundation
import JellyfinAPI
import SwiftUI

extension BaseItemPerson: Poster {

    typealias Environment = BaseItemDto.Environment

    var preferredPosterDisplayType: PosterDisplayType {
        .portrait
    }

    var subtitle: String? {
        displayRole
    }

    var systemImage: String {
        "person.fill"
    }

    var posterLabel: some View {
        BaseItemDto(person: self).posterLabel
    }

    var posterContextMenu: some View {
        BaseItemDto(person: self).posterContextMenu
    }

    func imageSources(
        for displayType: PosterDisplayType,
        environment: Environment
    ) -> [ImageSource] {
        BaseItemDto(person: self)
            .imageSources(
                for: displayType,
                environment: environment
            )
    }
}
