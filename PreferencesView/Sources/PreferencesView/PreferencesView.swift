//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

public struct PreferencesView<Content: View>: UIViewControllerRepresentable {

    private let content: Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    public func makeUIViewController(context: Context) -> some UIViewController {
        UIPreferencesHostingController { content }
    }

    public func updateUIViewController(_ uiViewController: some UIViewController, context: Context) {}
}
