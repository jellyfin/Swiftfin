//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: mainly used as a view to hold views for states
//       but doesn't work with animations/transitions.
//       Look at alternative with just ZStack and remove

struct WrappedView<Content: View>: View {

    @ViewBuilder
    let content: () -> Content

    var body: some View {
        content()
    }
}
