//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavigationBarDrawerView<Content: View, Drawer: View>: UIViewControllerRepresentable {

    private let buttons: () -> Drawer
    private let content: () -> Content

    init(
        @ViewBuilder buttons: @escaping () -> Drawer,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.buttons = buttons
        self.content = content
    }

    func makeUIViewController(context: Context) -> UINavigationBarDrawerHostingController<Content, Drawer> {
        UINavigationBarDrawerHostingController<Content, Drawer>(buttons: buttons, content: content)
    }

    func updateUIViewController(_ uiViewController: UINavigationBarDrawerHostingController<Content, Drawer>, context: Context) {}
}

class UINavigationBarDrawerHostingController<Content: View, Drawer: View>: UIHostingController<Content> {

    private let drawer: () -> Drawer
    private let content: () -> Content

    // TODO: see if we can get the height instead from the view passed in
    private let drawerHeight: CGFloat = 36

    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()

    private lazy var drawerButtonsView: UIHostingController<Drawer> = {
        let drawerButtonsView = UIHostingController(rootView: drawer())
        drawerButtonsView.view.translatesAutoresizingMaskIntoConstraints = false
        drawerButtonsView.view.backgroundColor = nil
        return drawerButtonsView
    }()

    init(
        buttons: @escaping () -> Drawer,
        content: @escaping () -> Content
    ) {
        self.drawer = buttons
        self.content = content

        super.init(rootView: content())
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        view.addSubview(blurView)

        addChild(drawerButtonsView)
        view.addSubview(drawerButtonsView.view)
        drawerButtonsView.didMove(toParent: self)

        NSLayoutConstraint.activate([
            drawerButtonsView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -drawerHeight),
            drawerButtonsView.view.heightAnchor.constraint(equalToConstant: drawerHeight),
            drawerButtonsView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            drawerButtonsView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: drawerButtonsView.view.bottomAnchor),
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
            .init(top: drawerHeight, left: 0, bottom: 0, right: 0)
        }
        set {
            super.additionalSafeAreaInsets = .init(top: drawerHeight, left: 0, bottom: 0, right: 0)
        }
    }
}
