//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavBarDrawerView: UIViewControllerRepresentable {

    private let buttons: () -> any View
    private let content: () -> any View

    init(
        @ViewBuilder buttons: @escaping () -> any View,
        @ViewBuilder content: @escaping () -> any View
    ) {
        self.buttons = buttons
        self.content = content
    }

    func makeUIViewController(context: Context) -> UINavBarDrawerHostingController {
        UINavBarDrawerHostingController(buttons: buttons, content: content)
    }

    func updateUIViewController(_ uiViewController: UINavBarDrawerHostingController, context: Context) {}
}

class UINavBarDrawerHostingController: UIViewController {

    private let buttons: () -> any View
    private let content: () -> any View

    // TODO: see if we can get the height instead from the view passed in
    private let drawerHeight: CGFloat = 36

    private lazy var navBarBlurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()

    private lazy var contentView: UIHostingController<AnyView> = {
        let contentView = UIHostingController(rootView: content().eraseToAnyView())
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.backgroundColor = nil
        return contentView
    }()

    private lazy var drawerButtonsView: UIHostingController<AnyView> = {
        let drawerButtonsView = UIHostingController(rootView: buttons().eraseToAnyView())
        drawerButtonsView.view.translatesAutoresizingMaskIntoConstraints = false
        drawerButtonsView.view.backgroundColor = nil
        return drawerButtonsView
    }()

    init(
        buttons: @escaping () -> any View,
        content: @escaping () -> any View
    ) {
        self.buttons = buttons
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        addChild(contentView)
        view.addSubview(contentView.view)
        contentView.didMove(toParent: self)

        view.addSubview(navBarBlurView)

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
            navBarBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            navBarBlurView.bottomAnchor.constraint(equalTo: drawerButtonsView.view.bottomAnchor),
            navBarBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        NSLayoutConstraint.activate([
            contentView.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
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
