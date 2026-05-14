//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavigationBarDrawerView<Content: View, Drawer: View>: UIViewControllerRepresentable {

    private let content: Content
    private let drawer: Drawer

    init(
        @ViewBuilder drawer: @escaping () -> Drawer,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content()
        self.drawer = drawer()
    }

    func makeUIViewController(context: Context) -> _UINavigationBarDrawerHostingController<Content, Drawer> {
        _UINavigationBarDrawerHostingController(content: content, drawer: drawer)
    }

    func updateUIViewController(_ uiViewController: _UINavigationBarDrawerHostingController<Content, Drawer>, context: Context) {}
}

class _UINavigationBarDrawerHostingController<Content: View, Drawer: View>: UIHostingController<Content> {

    private let drawer: Drawer
    private var drawerHeight: CGFloat = 0

    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()

    private lazy var drawerView: UIHostingController<Drawer> = {
        let drawerButtonsView = UIHostingController(rootView: drawer)
        drawerButtonsView.view.translatesAutoresizingMaskIntoConstraints = false
        drawerButtonsView.view.backgroundColor = nil
        return drawerButtonsView
    }()

    init(
        content: Content,
        drawer: Drawer
    ) {
        self.drawer = drawer
        super.init(rootView: content)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil
        view.addSubview(blurView)

        addChild(drawerView)
        view.addSubview(drawerView.view)
        drawerView.didMove(toParent: self)

        drawerHeight = drawerView.sizeThatFits(
            in: .init(
                width: view.frame.width,
                height: CGFloat.greatestFiniteMagnitude
            )
        )
        .height

        NSLayoutConstraint.activate([
            drawerView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -drawerHeight),
            drawerView.view.heightAnchor.constraint(equalToConstant: drawerHeight),
            drawerView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            drawerView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: drawerView.view.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }

    override var additionalSafeAreaInsets: UIEdgeInsets {
        get {
            .init(
                top: drawerHeight,
                left: 0,
                bottom: 0,
                right: 0
            )
        }
        set {
            super.additionalSafeAreaInsets = .init(
                top: drawerHeight,
                left: 0,
                bottom: 0,
                right: 0
            )
        }
    }
}
