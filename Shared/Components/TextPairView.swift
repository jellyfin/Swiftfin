//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: steal from SwiftUI, rename to something like
//       `LabeledContentView` with `label` and `value`

struct TextPairView: View {

    private let leading: Text
    private let trailing: Text

    var body: some View {
        HStack {
            leading
                .foregroundStyle(.primary)

            Spacer()

            trailing
                .foregroundStyle(.secondary)
        }
    }
}

extension TextPairView {

    init(_ textPair: TextPair) {
        self.init(
            leading: Text(textPair.title),
            trailing: Text(textPair.subtitle)
        )
    }

    init(leading: String, trailing: String) {
        self.init(
            leading: Text(leading),
            trailing: Text(trailing)
        )
    }

    init(_ title: String, value: @autoclosure () -> Text) {
        self.init(
            leading: Text(title),
            trailing: value()
        )
    }
}
