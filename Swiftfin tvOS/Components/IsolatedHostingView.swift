//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// Once a tvOS view contains any UIKit view, focus behave erratically in the same SwiftUI
// container (ScrollView). Hosting the content in its own `UIHostingController` resolves this.
struct IsolatedHostingView<Content: View>: UIViewControllerRepresentable {

    let content: Content

    private func rootView(context: Context) -> AnyView {
        AnyView(
            content
                .environment(\.router, context.environment.router)
        )
    }

    func makeUIViewController(context: Context) -> UIHostingController<AnyView> {
        let controller = UIHostingController(rootView: rootView(context: context))
        controller.view.backgroundColor = .clear
        controller.safeAreaRegions = []
        return controller
    }

    func updateUIViewController(_ controller: UIHostingController<AnyView>, context: Context) {
        controller.rootView = rootView(context: context)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiViewController controller: UIHostingController<AnyView>,
        context: Context
    ) -> CGSize? {
        let width = proposal.replacingUnspecifiedDimensions().width
        let height = controller.sizeThatFits(in: CGSize(width: width, height: .infinity)).height

        return CGSize(width: width, height: height)
    }
}
