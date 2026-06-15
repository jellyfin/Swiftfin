//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVKit
import SwiftUI

struct PlaybackRoutePickerView: UIViewRepresentable {

    @Binding
    var present: Bool

    let onBeginPresenting: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onBeginPresenting: onBeginPresenting)
    }

    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()
        routePickerView.delegate = context.coordinator
        routePickerView.prioritizesVideoDevices = true
        routePickerView.tintColor = .clear
        routePickerView.activeTintColor = .clear
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

    class Coordinator: NSObject, AVRoutePickerViewDelegate {

        private let onBeginPresenting: () -> Void

        init(onBeginPresenting: @escaping () -> Void) {
            self.onBeginPresenting = onBeginPresenting
        }

        func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            onBeginPresenting()
        }
    }
}
