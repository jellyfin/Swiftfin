//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension RemoteImageInfo: @retroactive Identifiable, Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        guard let height, let width else {
            return .square
        }

        return width > height ? .landscape : .portrait
    }

    var displayTitle: String {
        providerName ?? L10n.unknown
    }

    var unwrappedIDHashOrZero: Int {
        id
    }

    var subtitle: String? {
        language
    }

    var systemImage: String {
        "photo"
    }

    public var id: Int {
        hashValue
    }

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: VoidButWithDefaultValue
    ) -> [ImageSource] {
        [.init(url: url?.url)]
    }

    @ViewBuilder
    func transform(image: Image) -> some View {
        switch type {
        case .logo:
            ContainerRelativeView(ratio: 0.95) {
                image
                    .aspectRatio(contentMode: .fit)
            }
        default:
            image
                .aspectRatio(contentMode: .fill)
        }
    }
}
