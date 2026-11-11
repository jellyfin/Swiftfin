//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CompactOrRegularView<Compact: View, Regular: View>: View {

    private let isCompact: (CGSize) -> Bool
    private let compactView: Compact
    private let regularView: Regular

    init(
        isCompact: Bool,
        @ContentBuilder compactView: @escaping () -> Compact,
        @ContentBuilder regularView: @escaping () -> Regular
    ) {
        self.isCompact = { _ in isCompact }
        self.compactView = compactView()
        self.regularView = regularView()
    }

    init(
        isCompact: @escaping (CGSize) -> Bool,
        @ContentBuilder compactView: @escaping () -> Compact,
        @ContentBuilder regularView: @escaping () -> Regular
    ) {
        self.isCompact = isCompact
        self.compactView = compactView()
        self.regularView = regularView()
    }

    @ContentBuilder
    var body: some View {
        GeometryReader { proxy in
            if isCompact(proxy.size) {
                compactView
            } else {
                regularView
            }
        }
    }
}
