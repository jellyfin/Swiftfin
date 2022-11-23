//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct RotateContentView: UIViewRepresentable {
    
    @ObservedObject
    private var proxy: Proxy
    
    func makeUIView(context: Context) -> UIRotateContentView {
        UIRotateContentView(initialView: nil)
    }
    
    func updateUIView(_ uiView: UIRotateContentView, context: Context) {
        uiView.update(with: proxy.currentView)
    }
    
    class Proxy: ObservableObject {
        
        @Published
        private(set) var currentView: UIView?
        
        func update(_ content: (() -> any View)?) {
            guard let content else {
                currentView = nil
                return
            }
            
            currentView = UIHostingController(rootView: AnyView(content())).view
        }
    }
}

extension RotateContentView {
    
    init() {
        self.proxy = .init()
    }
    
    func proxy(_ proxy: Proxy) -> Self {
        copy(modifying: \.proxy, with: proxy)
    }
}

class UIRotateContentView: UIView {

    private(set) var currentView: UIView?

    init(initialView: UIView?) {
        super.init(frame: .zero)
        
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
}
