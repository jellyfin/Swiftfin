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

    /// A banner pinned flush to the TOP of a poster. Unlike `posterOverlayRegistry` (which is clipped
    /// INSIDE the poster's rounded-corner clip — so a large corner radius rounds the banner's bottom),
    /// the top banner is drawn OVER the clipped poster and given its own top-rounded / bottom-FLAT clip
    /// so its bottom edge never curves regardless of poster size. See `PosterButton`.
    @Entry
    var posterTopBannerRegistry: TypeViewRegistry = .init()
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

    /// Registers a flush-top banner for posters of type `V` (e.g. "UPCOMING" / "REQUEST?"). Rendered
    /// over the poster with a flat bottom edge (see `posterTopBannerRegistry`).
    func posterTopBanner<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (V) -> some View
    ) -> some View {
        modifier(
            EnvironmentView.Registar(
                content: { AnyView(content($0)) },
                keyPath: \.posterTopBannerRegistry
            )
        )
    }
}
