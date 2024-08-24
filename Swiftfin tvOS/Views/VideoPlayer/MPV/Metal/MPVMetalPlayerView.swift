//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct MPVMetalPlayerView: UIViewControllerRepresentable {
    @ObservedObject
    var coordinator: Coordinator

    func makeUIViewController(context: Context) -> some UIViewController {
        let mpv = MPVMetalViewController()
        mpv.playDelegate = coordinator
        mpv.playUrl = coordinator.playUrl

        context.coordinator.player = mpv
        return mpv
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        coordinator
    }

    func play(_ url: URL) -> Self {
        coordinator.playUrl = url
        return self
    }

    func onPropertyChange(_ handler: @escaping (MPVMetalViewController, String, Any?) -> Void) -> Self {
        coordinator.onPropertyChange = handler
        return self
    }

    @MainActor
    public final class Coordinator: MPVPlayerDelegate, ObservableObject {
        weak var player: MPVMetalViewController?

        var playUrl: URL?
        var onPropertyChange: ((MPVMetalViewController, String, Any?) -> Void)?

        func play(_ url: URL) {
            player?.loadFile(url)
        }

        func propertyChange(mpv: OpaquePointer, propertyName: String, data: Any?) {
            guard let player else { return }

            self.onPropertyChange?(player, propertyName, data)
        }
    }
}
