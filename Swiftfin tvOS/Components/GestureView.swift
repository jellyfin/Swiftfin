//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

extension EnvironmentValues {

    @Entry
    var panGestureDirection: Direction = .all
}

struct GestureView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        view.addGestureRecognizer(context.coordinator.panGesture)
        view.backgroundColor = .clear

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.panAction = context.environment.panAction
        context.coordinator.panGesture.direction = context.environment.panGestureDirection
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {

        lazy var panGesture: DirectionalPanGestureRecognizer! = {
            .init(
                direction: .vertical,
                target: self,
                action: #selector(handlePan)
            )
        }()

        var panAction: PanAction? {
            didSet { panGesture.isEnabled = panAction != nil }
        }

        @objc
        func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }

            let translation = gesture.translation(in: view)
            let velocity = gesture.velocity(in: view)
            let location = gesture.location(in: view)
            let unitPoint = UnitPoint(
                x: location.x / view.bounds.width,
                y: location.y / view.bounds.height
            )

            panAction?(
                translation: translation,
                velocity: velocity,
                location: location,
                unitPoint: unitPoint,
                state: gesture.state
            )
        }
    }
}
