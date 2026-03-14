//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EnvironmentValues {

    @Entry
    var posterOverlayRegistry: TypeViewRegistry = .init()
}

extension View {

    func posterOverlay<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (V) -> some View
    ) -> some View {
        modifier(
            EnvironmentView.Registar(
                content: { AnyView(content($0)) },
                keyPath: \.posterOverlayRegistry
            )
        )
    }
}
