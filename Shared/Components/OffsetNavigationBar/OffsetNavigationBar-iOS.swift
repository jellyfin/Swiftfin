//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import SwiftUI

struct OffsetNavigationBar<Content: View>: View {

    private let content: Content
    private let isEnabled: Bool

    init(
        isEnabled: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content()
        self.isEnabled = isEnabled
    }

    var body: some View {
        if isEnabled {
            NavigationBarTitleHiddenView {
                content
            }
            .ignoresSafeArea()
        } else {
            content
        }
    }
}

private struct NavigationBarTitleHiddenView<Content: View>: UIViewControllerRepresentable {

    private let content: Content

    init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> NavigationBarTitleHiddenHostingController<Content> {
        NavigationBarTitleHiddenHostingController<Content>(rootView: content)
    }

    func updateUIViewController(_ uiViewController: NavigationBarTitleHiddenHostingController<Content>, context: Context) {
        uiViewController.hideNavigationTitle()
    }
}

private class NavigationBarTitleHiddenHostingController<Content: View>: UIHostingController<Content> {

    private var hasCalledWillDisappear = false

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil
    }

    func hideNavigationTitle() {
        guard !hasCalledWillDisappear else { return }

        let hiddenTitleColor = UIColor.label.withAlphaComponent(0)

        navigationController?.navigationBar
            .titleTextAttributes = [NSAttributedString.Key.foregroundColor: hiddenTitleColor]
        navigationController?.navigationBar
            .largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: hiddenTitleColor]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        hasCalledWillDisappear = false

        hideNavigationTitle()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        hasCalledWillDisappear = true

        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }
}
#endif
