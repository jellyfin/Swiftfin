//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

/// SwiftUI Wrapper for `UIActivityViewController`
struct ShareSheet: View {

    @Router
    private var router

    let urls: [URL]

    var body: some View {
        _ActivityView(activityItems: urls as [Any]) {
            router.dismiss()
        }
        .presentationDetents([.fraction(0.4), .large])
        .ignoresSafeArea()
    }

    private struct _ActivityView: UIViewControllerRepresentable {

        let activityItems: [Any]
        let onComplete: () -> Void

        func makeUIViewController(context: Context) -> UIActivityViewController {
            let viewController = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
            viewController.completionWithItemsHandler = { _, _, _, _ in
                onComplete()
            }
            return viewController
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
}
