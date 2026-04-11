//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@ViewBuilder
func SecureField(
    _ title: String,
    text: Binding<String>,
    maskToggle: SwiftUI.SecureField<EmptyView>.MaskToggleBehavior
) -> some View {
    #if os(iOS)
    if maskToggle == .enabled {
        _UnmaskSecureField(
            title,
            text: text
        )
    } else {
        SecureField(
            title,
            text: text
        )
    }
    #else
    SecureField(
        title,
        text: text
    )
    #endif
}

extension SecureField {

    enum MaskToggleBehavior {
        case disabled
        case enabled
    }
}
