//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavigationBarOffsetView<Content: View>: UIViewControllerRepresentable {

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

    func makeUIViewController(context: Context) -> UINavigationBarOffsetHostingController<Content> {
        UINavigationBarOffsetHostingController(rootView: content())
    }

    func updateUIViewController(_ uiViewController: UINavigationBarOffsetHostingController<Content>, context: Context) {
        uiViewController.scrollViewDidScroll(scrollViewOffset, start: start, end: end)
    }
}

class UINavigationBarOffsetHostingController<Content: View>: UIHostingController<Content> {

    private var lastAlpha: CGFloat = 0

    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        view.addSubview(blurView)
        blurView.alpha = 0

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    func scrollViewDidScroll(_ offset: CGFloat, start: CGFloat, end: CGFloat) {

        let diff = end - start
        let currentProgress = (offset - start) / diff
        let alpha = clamp(currentProgress, min: 0, max: 1)

        navigationController?.navigationBar
            .titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(alpha)]
        blurView.alpha = alpha
        lastAlpha = alpha
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar
            .titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(lastAlpha)]
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
}
