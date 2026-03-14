//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct RotateContentView: UIViewRepresentable {

    @ObservedObject
    var proxy: Proxy

    func makeUIView(context: Context) -> UIRotateContentView {
        UIRotateContentView(initialView: nil, proxy: proxy)
    }

    func updateUIView(_ uiView: UIRotateContentView, context: Context) {}

    class Proxy: ObservableObject {

        weak var rotateContentView: UIRotateContentView?

        func update(_ content: () -> any View) {

            let newHostingController = UIHostingController(rootView: AnyView(content()), ignoreSafeArea: true)
            newHostingController.view.translatesAutoresizingMaskIntoConstraints = false
            newHostingController.view.backgroundColor = .clear

            rotateContentView?.update(with: newHostingController.view)
        }
    }
}

class UIRotateContentView: UIView {

    private(set) var currentView: UIView?
    var proxy: RotateContentView.Proxy

    init(initialView: UIView?, proxy: RotateContentView.Proxy) {
        self.proxy = proxy

        super.init(frame: .zero)

        proxy.rotateContentView = self

        guard let initialView else { return }

        initialView.translatesAutoresizingMaskIntoConstraints = false
        initialView.alpha = 0

        addSubview(initialView)
        NSLayoutConstraint.activate([
            initialView.topAnchor.constraint(equalTo: topAnchor),
            initialView.bottomAnchor.constraint(equalTo: bottomAnchor),
            initialView.leftAnchor.constraint(equalTo: leftAnchor),
            initialView.rightAnchor.constraint(equalTo: rightAnchor),
        ])

        self.currentView = initialView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with newView: UIView?) {

        guard let newView else {
            UIView.animate(withDuration: 0.3) {
                self.currentView?.alpha = 0
            } completion: { _ in
                self.currentView?.removeFromSuperview()
                self.currentView = newView
            }
            return
        }

        newView.translatesAutoresizingMaskIntoConstraints = false
        newView.alpha = 0

        addSubview(newView)
        NSLayoutConstraint.activate([
            newView.topAnchor.constraint(equalTo: topAnchor),
            newView.bottomAnchor.constraint(equalTo: bottomAnchor),
            newView.leftAnchor.constraint(equalTo: leftAnchor),
            newView.rightAnchor.constraint(equalTo: rightAnchor),
        ])

        UIView.animate(withDuration: 0.3) {
            newView.alpha = 1
            self.currentView?.alpha = 0
        } completion: { _ in
            self.currentView?.removeFromSuperview()
            self.currentView = newView
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        currentView?.hitTest(point, with: event)
    }
}
