//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TintedMaterial: UIViewRepresentable {

    let tint: Color

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        set(tint: tint, for: uiView)
    }

    private func set(tint: Color, for view: UIVisualEffectView) {
        let overlayView = view.subviews.first { type(of: $0) == NSClassFromString("_UIVisualEffectSubview") }
        overlayView?.backgroundColor = UIColor(tint.opacity(0.75))
    }
}
