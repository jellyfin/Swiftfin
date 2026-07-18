//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EmptyLabel: View {

    private let title: Text

    init(_ text: some WithText) {
        self.title = text.textBody
    }

    var body: some View {
        Label {
            title
        } icon: {
            EmptyView()
        }
    }
}
