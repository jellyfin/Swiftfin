//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension LabeledContentStyle where Self == LearnMoreLabeledContentStyle {

    static var learnMore: LearnMoreLabeledContentStyle {
        LearnMoreLabeledContentStyle()
    }
}

struct LearnMoreLabeledContentStyle: LabeledContentStyle {

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.headline)
                .foregroundStyle(.primary)

            configuration.content
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

extension LabeledContentStyle where Self == ItemAttributeLabeledContentStyle {

    static var itemAttribute: ItemAttributeLabeledContentStyle {
        ItemAttributeLabeledContentStyle()
    }
}

struct ItemAttributeLabeledContentStyle: LabeledContentStyle {

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.headline)
                .foregroundStyle(.primary)

            configuration.content
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
