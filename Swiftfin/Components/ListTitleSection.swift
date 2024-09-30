//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: image

struct ListTitleSection: View {

    private let title: String
    private let description: String?
    private let onLearnMore: (() -> Void)?

    var body: some View {
        Section {
            VStack(alignment: .center, spacing: 10) {

                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)

                if let description {
                    Text(description)
                        .multilineTextAlignment(.center)
                }

                if let onLearnMore {
                    Button("Learn More\u{2026}", action: onLearnMore)
                }
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
        }
    }
}

extension ListTitleSection {

    init(
        _ title: String,
        description: String? = nil
    ) {
        self.init(
            title: title,
            description: description,
            onLearnMore: nil
        )
    }

    init(
        _ title: String,
        description: String? = nil,
        onLearnMore: @escaping () -> Void
    ) {
        self.init(
            title: title,
            description: description,
            onLearnMore: onLearnMore
        )
    }
}
