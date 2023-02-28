//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DotHStack: View {

    @ViewBuilder
    var content: () -> any View

    var body: some View {
        SeparatorHStack(content)
            .separator {
                Circle()
                    .frame(width: 5, height: 5)
                    .padding(.horizontal, 10)
            }
    }
}
