//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVKit
import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct AirPlay: View {

        @Environment(\.isInMenu)
        private var isInMenu

        @State
        private var hasMultipleRoutes = false
        @State
        private var routeDetector = AVRouteDetector()

        var body: some View {
            ZStack {
                // `AVRoutePickerView` cannot render within a menu
                if !isInMenu, hasMultipleRoutes {
                    Button(L10n.airPlay, systemImage: VideoPlayerActionButton.airPlay.systemImage) {}
                        .videoPlayerActionButtonTransition()
                        .overlay {
                            RoutePickerView()
                                .edgePadding()
                        }
                }
            }
            .onAppear {
                routeDetector.isRouteDetectionEnabled = true
                hasMultipleRoutes = routeDetector.multipleRoutesDetected
            }
            .onDisappear {
                routeDetector.isRouteDetectionEnabled = false
            }
            .onNotification(.avRouteDetectorMultipleRoutesDetected) { _ in
                hasMultipleRoutes = routeDetector.multipleRoutesDetected
            }
        }
    }

    private struct RoutePickerView: UIViewRepresentable {

        func makeUIView(context: Context) -> AVRoutePickerView {
            let routePickerView = AVRoutePickerView()

            routePickerView.prioritizesVideoDevices = true
            routePickerView.tintColor = .clear
            routePickerView.activeTintColor = .clear

            return routePickerView
        }

        func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
    }
}
