//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

@available(*, deprecated, message: "Use `Material` or `VisualEffectView` instead")
typealias BlurView = VisualEffectView

struct VisualEffectView: UIViewRepresentable {

    private let effect: UIVisualEffect
    private let tint: Color?

    init(
        blur style: UIBlurEffect.Style = .regular,
        tint: Color? = nil
    ) {
        self.effect = UIBlurEffect(style: style)
        self.tint = tint
    }

    init(
        effect: UIVisualEffect,
        tint: Color? = nil
    ) {
        self.effect = effect
        self.tint = tint
    }

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect

        let overlayView = uiView.subviews.first { type(of: $0) == NSClassFromString("_UIVisualEffectSubview") }

        if let tint {
            overlayView?.backgroundColor = UIColor(tint)
        } else {
            overlayView?.backgroundColor = nil
        }
    }
}
