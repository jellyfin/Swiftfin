//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@available(*, deprecated, message: "Use Button directly with an empty action")
func Button(
    role: ButtonRole? = nil,
    @ViewBuilder label: @escaping () -> some View
) -> some View {
    Button(role: role, action: {}, label: label)
        .foregroundStyle(.primary, .secondary)
}

@available(*, deprecated, message: "Use Button directly with an empty action")
func Button(
    _ title: String,
    role: ButtonRole? = nil
) -> some View {
    Button(title, role: role, action: {})
        .foregroundStyle(.primary, .secondary)
}
