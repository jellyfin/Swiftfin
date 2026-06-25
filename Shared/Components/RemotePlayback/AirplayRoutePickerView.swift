//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVKit
import SwiftUI

struct AirplayRoutePickerModifier: ViewModifier {

    @Binding
    var present: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                AirplayRoutePickerView(present: $present)
                    .allowsHitTesting(false)
            }
    }
}

private struct AirplayRoutePickerView: UIViewRepresentable {

    @Binding
    var present: Bool

    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()

        routePickerView.prioritizesVideoDevices = true
        routePickerView.tintColor = .clear
        routePickerView.activeTintColor = .clear
        routePickerView.alpha = 0

        return routePickerView
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        guard present else { return }

        DispatchQueue.main.async {
            present = false

            for subview in uiView.subviews {
                if let button = subview as? UIButton {
                    button.sendActions(for: .touchUpInside)
                }
            }
        }
    }
}
