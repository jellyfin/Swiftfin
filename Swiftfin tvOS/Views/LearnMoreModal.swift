//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@available(*, deprecated, message: "Use `Section(:content:learnMore:)` and a `Form` with an image instead")
struct LearnMoreModal: View {

    private let content: AnyView

    // MARK: - Initializer

    init(@LabeledContentBuilder content: () -> AnyView) {
        self.content = content()
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
                .labeledContentStyle(LearnMoreLabeledContentStyle())
                .foregroundStyle(Color.primary, Color.secondary)
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Material.regular)
        }
        .padding()
    }
}
