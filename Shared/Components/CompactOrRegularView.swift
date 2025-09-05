//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CompactOrRegularView<Compact: View, Regular: View>: View {

    private let shouldBeCompact: (CGSize) -> Bool
    private let compactView: Compact
    private let regularView: Regular

    init(
        shouldBeCompact: Bool,
        @ViewBuilder compactView: @escaping () -> Compact,
        @ViewBuilder regularView: @escaping () -> Regular
    ) {
        self.shouldBeCompact = { _ in shouldBeCompact }
        self.compactView = compactView()
        self.regularView = regularView()
    }

    init(
        shouldBeCompact: @escaping (CGSize) -> Bool,
        @ViewBuilder compactView: @escaping () -> Compact,
        @ViewBuilder regularView: @escaping () -> Regular
    ) {
        self.shouldBeCompact = shouldBeCompact
        self.compactView = compactView()
        self.regularView = regularView()
    }

    var body: some View {
        GeometryReader { proxy in
            if shouldBeCompact(proxy.size) {
                compactView
            } else {
                regularView
            }
        }
    }
}
