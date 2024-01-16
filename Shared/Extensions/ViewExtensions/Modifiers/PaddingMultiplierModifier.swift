//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PaddingMultiplierModifier: ViewModifier {

    let edges: Edge.Set
    let multiplier: Int

    func body(content: Content) -> some View {
        content
            .if(multiplier > 0) { view in
                view.padding()
                    .padding(multiplier: multiplier - 1, edges)
            }
    }
}
