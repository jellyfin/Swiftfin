//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FullScreenMenuModifier<Contents: View>: ViewModifier {

    // MARK: - Dialog State

    @Binding
    var isPresented: Bool

    // MARK: - Overlay Menu Contents

    let title: String?
    let subtitle: String?
    let orientation: FullScreenMenu.Orientation
    let contents: Contents
    let footer: Contents?

    // MARK: - Overlay Menu Actions

    let onDisappear: (() -> Void)?

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                FullScreenMenu(title, subtitle: subtitle, orientation: orientation)
                    .contentView {
                        contents
                    }
                    .footerView {
                        footer
                    }
                    .onDisappear {
                        onDisappear?()
                    }
            }
    }
}
