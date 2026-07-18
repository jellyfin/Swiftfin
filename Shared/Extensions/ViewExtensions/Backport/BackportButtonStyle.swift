//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
protocol BackportButtonStyle {

    associatedtype Body: View

    typealias Configuration = PrimitiveButtonStyleConfiguration

    @ViewBuilder
    func makeBody(configuration: Configuration) -> Body
}

struct BackportPrimitiveButtonStyle<Style: BackportButtonStyle>: PrimitiveButtonStyle {

    let style: Style

    func makeBody(configuration: Configuration) -> some View {
        style.makeBody(configuration: configuration)
    }
}
