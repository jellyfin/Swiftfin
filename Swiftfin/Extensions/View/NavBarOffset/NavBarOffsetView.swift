//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavBarOffsetView<Content: View>: UIViewControllerRepresentable {

    @Binding
    private var scrollViewOffset: CGFloat

    private let start: CGFloat
    private let end: CGFloat
    private let content: () -> Content

    init(
        scrollViewOffset: Binding<CGFloat>,
        start: CGFloat,
        end: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._scrollViewOffset = scrollViewOffset
        self.start = start
        self.end = end
        self.content = content
    }

    func makeUIViewController(context: Context) -> UINavBarOffsetHostingController<Content> {
        UINavBarOffsetHostingController(rootView: content())
    }

    func updateUIViewController(_ uiViewController: UINavBarOffsetHostingController<Content>, context: Context) {
        uiViewController.scrollViewDidScroll(scrollViewOffset, start: start, end: end)
    }
}

class UINavBarOffsetHostingController<Content: View>: UIHostingController<Content> {

    private var driver: Driver!
    private var customButton: _UIHostingView<BackButtonView>!
    private var lastAlpha: CGFloat = 0

    private lazy var navBarBlurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        // bar

        view.addSubview(navBarBlurView)
        navBarBlurView.alpha = 0

        NSLayoutConstraint.activate([
            navBarBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            navBarBlurView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBarBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        // back button

        driver = Driver()

        driver.action = { [weak self] in
            guard let self else { return }

            if let vcs = navigationController?.viewControllers, vcs.count > 1 {
                navigationController?.popViewController(animated: true)
            } else {
                topNavigationController?.popViewController(animated: true)
            }
        }

        driver.postTransitionAction = { [weak self] isChevron in
            guard let parent = self?.parent, let customButton = self?.customButton else { return }

            if isChevron {
                parent.navigationItem.leftBarButtonItem = nil
                parent.navigationItem.leftItemsSupplementBackButton = true
            } else {
                let backBarButton = UIBarButtonItem(customView: customButton)
                parent.navigationItem.leftBarButtonItem = backBarButton
                parent.navigationItem.leftItemsSupplementBackButton = false
            }
        }

        customButton = _UIHostingView(rootView: BackButtonView(driver: driver))
    }

    func scrollViewDidScroll(_ offset: CGFloat, start: CGFloat, end: CGFloat) {
        let diff = end - start
        let currentProgress = (offset - start) / diff
        let alpha = clamp(currentProgress, min: 0, max: 1)

        // bar

        navigationController?.navigationBar
            .titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(alpha)]
        navBarBlurView.alpha = alpha
        lastAlpha = alpha

        // back button

        let shouldBeChevron = alpha >= 0.5

        if driver.isChevron != shouldBeChevron {
            driver.transition(toChevron: shouldBeChevron)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // bar

        navigationController?.navigationBar
            .titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(lastAlpha)]
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()

        // back button

        guard let parent else { return }

        if lastAlpha < 0.5 {
            let backBarButton = UIBarButtonItem(customView: customButton)
            parent.navigationItem.leftBarButtonItem = backBarButton
            parent.navigationItem.leftItemsSupplementBackButton = false

            driver.isChevron = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        driver.isChevron = lastAlpha >= 0.5
    }
}
