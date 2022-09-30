//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct GestureView: UIViewRepresentable {

    private var onPinch: (UIGestureRecognizer.State, CGFloat) -> Void
    private var onTap: () -> Void
    private var onVerticalPan: (CGPoint, CGPoint) -> Void
    private var onHorizontalPan: (CGPoint, CGPoint) -> Void

    func makeUIView(context: Context) -> UIGestureView {
        UIGestureView(
            onPinch: onPinch,
            onTap: onTap,
            onVerticalPan: onVerticalPan,
            onHorizontalPan: onHorizontalPan
        )
    }

    func updateUIView(_ uiView: UIGestureView, context: Context) {}
}

extension GestureView {

    init() {
        self.onPinch = { _, _ in }
        self.onTap = {}
        self.onVerticalPan = { _, _ in }
        self.onHorizontalPan = { _, _ in }
    }

    func onPinch(_ action: @escaping (UIGestureRecognizer.State, CGFloat) -> Void) -> Self {
        copy(modifying: \.onPinch, with: action)
    }

    func onTap(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onTap, with: action)
    }

    func onVerticalPan(_ action: @escaping (CGPoint, CGPoint) -> Void) -> Self {
        copy(modifying: \.onVerticalPan, with: action)
    }

    func onHorizontalPan(_ action: @escaping (CGPoint, CGPoint) -> Void) -> Self {
        copy(modifying: \.onVerticalPan, with: action)
    }
}

class UIGestureView: UIView {

    private let onPinch: (UIGestureRecognizer.State, CGFloat) -> Void
    private let onTap: () -> Void
    private let onVerticalPan: (CGPoint, CGPoint) -> Void
    private let onHorizontalPan: (CGPoint, CGPoint) -> Void

    init(
        onPinch: @escaping (UIGestureRecognizer.State, CGFloat) -> Void,
        onTap: @escaping () -> Void,
        onVerticalPan: @escaping (CGPoint, CGPoint) -> Void,
        onHorizontalPan: @escaping (CGPoint, CGPoint) -> Void
    ) {
        self.onPinch = onPinch
        self.onTap = onTap
        self.onVerticalPan = onVerticalPan
        self.onHorizontalPan = onHorizontalPan
        super.init(frame: .zero)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPerformPinch(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPerformTap(_:)))
        let verticalPanGesture = PanDirectionGestureRecognizer(
            direction: .vertical,
            target: self,
            action: #selector(didPerformVerticalPan(_:))
        )
        let horizontalPanGesture = PanDirectionGestureRecognizer(
            direction: .horizontal,
            target: self,
            action: #selector(didPerformHorizontalPan(_:))
        )

        addGestureRecognizer(pinchGesture)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(verticalPanGesture)
        addGestureRecognizer(horizontalPanGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didPerformPinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        onPinch(gestureRecognizer.state, gestureRecognizer.scale)
    }

    @objc
    private func didPerformTap(_ gestureRecognizer: UITapGestureRecognizer) {
        onTap()
    }

    @objc
    private func didPerformVerticalPan(_ gestureRecognizer: PanDirectionGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        let translation = gestureRecognizer.translation(in: self)
        onVerticalPan(location, translation)
    }

    @objc
    private func didPerformHorizontalPan(_ gestureRecognizer: PanDirectionGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        let translation = gestureRecognizer.translation(in: self)
        onHorizontalPan(location, translation)
    }
}
