//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: remove when iOS 15 support removed
struct iOS15View<iOS15Content: View, Content: View>: View {

    let iOS15: () -> iOS15Content
    let content: () -> Content

    var body: some View {
        if #available(iOS 16, *) {
            content()
        } else {
            iOS15()
        }
    }
}
