//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

public struct VisibilityModifier: ViewModifier {

    @usableFromInline
    let isVisible: Bool

    @usableFromInline
    init(isVisible: Bool) {
        self.isVisible = isVisible
    }

    @inlinable
    public func body(content: Content) -> some View {
        content.opacity(isVisible ? 1 : 0)
    }
}
