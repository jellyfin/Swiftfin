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

    struct Environment: WithDefaultValue, WithImageSourceOptions {

        var maxWidth: CGFloat?
        var maxHeight: CGFloat?
        var quality: Int?

        static var `default`: Self {
            .init()
        }
    }

    var preferredPosterDisplayType: PosterDisplayType {
        .portrait
    }

    var subtitle: String? {
        firstRole
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

    func portraitImageSources(
        environment: Environment
    ) -> [ImageSource] {
        BaseItemDto(person: self)
            .portraitImageSources(
                environment: baseItemDtoEnvironment(from: environment)
            )
    }

    private func baseItemDtoEnvironment(from environment: Environment) -> BaseItemDto.Environment {
        var itemEnvironment = BaseItemDto.Environment.default
        itemEnvironment.maxWidth = environment.maxWidth
        itemEnvironment.maxHeight = environment.maxHeight
        itemEnvironment.quality = environment.quality

        return itemEnvironment
    }
}
