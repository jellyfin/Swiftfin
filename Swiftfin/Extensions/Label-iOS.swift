//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: see if could be moved to `Shared`

// MARK: EpisodeSelectorLabelStyle

extension LabelStyle where Self == EpisodeSelectorLabelStyle {

    static var episodeSelector: EpisodeSelectorLabelStyle {
        EpisodeSelectorLabelStyle()
    }
}

struct EpisodeSelectorLabelStyle: LabelStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title

            configuration.icon
        }
        .font(.headline)
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background {
            Color.tertiarySystemFill
                .cornerRadius(10)
        }
        .compositingGroup()
        .shadow(radius: 1)
        .font(.caption)
    }
}

// MARK: SectionFooterWithImageLabelStyle

extension TitleAndIconLabelStyle {

    var trailingIcon: TrailingIconReversedButtonStyle {
        TrailingIconReversedButtonStyle()
    }
}

struct TrailingIconReversedButtonStyle: LabelStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title

            configuration.icon
        }
    }
}
