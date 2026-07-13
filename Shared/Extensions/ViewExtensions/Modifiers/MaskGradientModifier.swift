//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct MaskGradientModifier: ViewModifier {

    enum Style {
        case linear
        case eased(EasedGradient.Curve)
    }

    typealias Stop = (location: CGFloat, opacity: CGFloat)

    let style: Style
    let stops: [Stop]

    private var gradientStops: [Gradient.Stop] {
        stops.map {
            Gradient.Stop(
                color: Color.black.opacity($0.opacity),
                location: $0.location
            )
        }
    }

    @ViewBuilder
    private var gradient: some View {
        switch style {
        case .linear:
            LinearGradient(
                stops: gradientStops,
                startPoint: .top,
                endPoint: .bottom
            )
        case let .eased(curve):
            EasedGradient(
                stops: gradientStops,
                startPoint: .top,
                endPoint: .bottom,
                curve: curve
            )
        }
    }

    func body(content: Content) -> some View {
        content
            .mask {
                gradient
            }
    }
}
