//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A button style that can provide a backported implementation of a newer
/// SwiftUI button style.
@MainActor
protocol BackportButtonStyle {

    associatedtype Body: View

    typealias Configuration = PrimitiveButtonStyleConfiguration

    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
}

extension Backport where Content: View {

    /// Sets the style for buttons in this view using a backported button style.
    func buttonStyle(
        _ style: some BackportButtonStyle
    ) -> some View {
        content.buttonStyle(
            BackportPrimitiveButtonStyle(style: style)
        )
    }
}

private struct BackportPrimitiveButtonStyle<Style: BackportButtonStyle>: PrimitiveButtonStyle {

    let style: Style

    func makeBody(configuration: Configuration) -> some View {
        style.makeBody(configuration: configuration)
    }
}
