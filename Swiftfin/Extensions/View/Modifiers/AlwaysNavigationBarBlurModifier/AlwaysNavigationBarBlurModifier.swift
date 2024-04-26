//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#warning("TODO: cleanup")

extension View {

    func alwaysNavigationBarBlur() -> some View {
        modifier(AlwaysNavigationBarBlurModifier())
    }
}

struct AlwaysNavigationBarBlurModifier: ViewModifier {

    func body(content: Content) -> some View {
        AlwaysNavigationBarBlurView {
            content
        }
        .ignoresSafeArea()
    }
}

struct AlwaysNavigationBarBlurView<Content: View>: UIViewControllerRepresentable {

    let content: () -> Content

    func makeUIViewController(context: Context) -> UIAlwaysNavigationBarBlurHostingController<Content> {
        UIAlwaysNavigationBarBlurHostingController(rootView: content())
    }

    func updateUIViewController(_ uiViewController: UIAlwaysNavigationBarBlurHostingController<Content>, context: Context) {}
}

class UIAlwaysNavigationBarBlurHostingController<Content: View>: UIHostingController<Content> {

    private lazy var blurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        return blurView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = nil

        view.addSubview(blurView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
}
