//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

private let drawerHeight: CGFloat = 36

struct NavBarDrawerView<Buttons: View, Content: View>: UIViewControllerRepresentable {

    private let buttons: () -> Buttons
    private let content: () -> Content

    init(
        @ViewBuilder buttons: @escaping () -> Buttons,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.buttons = buttons
        self.content = content
    }

    func makeUIViewController(context: Context) -> UINavBarDrawerHostingController<Buttons, Content> {
        UINavBarDrawerHostingController(buttons: buttons, content: content)
    }

    func updateUIViewController(_ uiViewController: UINavBarDrawerHostingController<Buttons, Content>, context: Context) {}
}

class UINavBarDrawerHostingController<Buttons: View, Content: View>: UIViewController {

    private let buttons: () -> Buttons
    private let content: () -> Content

    private lazy var navBarBlurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()

    private lazy var contentView: UIHostingController<Content> = {
        let contentView = UIHostingController(rootView: content())
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.backgroundColor = nil
        return contentView
    }()

    private lazy var drawerButtonsView: UIHostingController<Buttons> = {
        let drawerButtonsView = UIHostingController(rootView: buttons())
        drawerButtonsView.view.translatesAutoresizingMaskIntoConstraints = false
        drawerButtonsView.view.backgroundColor = nil
        return drawerButtonsView
    }()

    init(
        buttons: @escaping () -> Buttons,
        content: @escaping () -> Content
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
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
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
