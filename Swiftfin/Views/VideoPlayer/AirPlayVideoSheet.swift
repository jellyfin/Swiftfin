//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import AVKit
import SwiftUI

@MainActor
extension NavigationRoute {

    static var airPlayVideo: NavigationRoute {
        NavigationRoute(
            id: "airPlayVideo",
            style: .sheet
        ) {
            AirPlayVideoSheet()
        }
    }
}

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct AirPlay: View {

        @Environment(MediaSession.self)
        private var mediaSession
        @Router
        private var router

        private let controller = AirPlayVideoController.shared

        @ContentBuilder
        var body: some View {
            // swiftlint:disable:next hard_coded_display_string
            Button("AirPlay", systemImage: VideoPlayerActionButton.airPlay.systemImage) {
                router.route(to: .airPlayVideo)
            }
            .disabled(controller.phase == .inactive && !mediaSession.canControlPlayback)
        }
    }
}

struct AirPlayVideoSheet: View {

    @Router
    private var router

    private let controller = AirPlayVideoController.shared

    private var footer: String {
        switch controller.phase {
        case .inactive:
            "Choose a TV with the AirPlay button. A stream it can play is prepared once it is selected."
        case .preparing:
            "Preparing a stream the TV can play."
        case .active:
            "You can close this and keep using the playback controls. To return, choose this device in the AirPlay picker."
        case .restoring:
            "This device takes over once its stream is ready."
        }
    }

    @ContentBuilder
    var body: some View {
        Form {
            Section {
                LabeledContent(controller.phase.displayTitle) {
                    if controller.phase.isTransitioning {
                        ProgressView()
                    } else {
                        AirPlayRoutePicker(
                            willPresent: controller.routePickerWillPresent,
                            didEnd: controller.routePickerDidEnd
                        )
                        .frame(width: 44, height: 44)
                    }
                }
            } footer: {
                Text(footer)
            }
        }
        .navigationTitle("AirPlay")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .presentationDetents([.medium])
    }
}

private struct AirPlayRoutePicker: UIViewRepresentable {

    let willPresent: () -> Void
    let didEnd: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = true
        view.tintColor = .label
        view.activeTintColor = .systemBlue
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        context.coordinator.willPresent = willPresent
        context.coordinator.didEnd = didEnd
    }

    final class Coordinator: NSObject, AVRoutePickerViewDelegate {

        var willPresent: () -> Void = {}
        var didEnd: () -> Void = {}

        func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            willPresent()
        }

        func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            didEnd()
        }
    }
}
#endif
