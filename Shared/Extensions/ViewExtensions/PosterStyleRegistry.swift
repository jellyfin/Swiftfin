//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol WithDefaultValue {
    static var `default`: Self { get }
}

// TODO: have layout values for `PosterHStack`?
//       - or be based on size/poster display value?

// TODO: rename `PosterButtonStyle`
struct PosterStyleEnvironment: WithDefaultValue {

    var displayType: PosterDisplayType
    var indicators: [PosterOverlayIndicator]
    var label: AnyView
    var overlay: AnyView
    var useParentImages: Bool
    var size: PosterDisplayType.Size

    init(
        displayType: PosterDisplayType = .portrait,
        indicators: [PosterOverlayIndicator] = [],
        label: some View = EmptyView(),
        overlay: some View = EmptyView(),
        useParentImages: Bool = false,
        size: PosterDisplayType.Size = .medium
    ) {
        self.displayType = displayType
        self.indicators = indicators
        self.label = label.eraseToAnyView()
        self.overlay = overlay.eraseToAnyView()
        self.useParentImages = useParentImages
        self.size = size
    }

    static let `default` = PosterStyleEnvironment(
        displayType: .portrait,
        indicators: [],
        label: EmptyView(),
        overlay: EmptyView(),
        useParentImages: false,
        size: .medium
    )
}

extension EnvironmentValues {

    @Entry
    var posterStyleRegistry: TypeKeyedDictionary<(Any) -> PosterStyleEnvironment> = .init()
}

extension View {

    @ViewBuilder
    func posterStyle<P: Poster>(
        for type: P.Type,
        style: PosterStyleEnvironment
    ) -> some View {
        posterStyle(for: type) { _ in
            style
        }
    }

    @ViewBuilder
    func posterStyle<P: Poster>(
        for type: P.Type,
        style: @escaping (P) -> PosterStyleEnvironment
    ) -> some View {
        posterStyle(for: type) { _, p in
            style(p)
        }
    }

    @ViewBuilder
    func posterStyle<P: Poster>(
        for type: P.Type,
        style: @escaping (PosterStyleEnvironment, P) -> PosterStyleEnvironment
    ) -> some View {
        modifier(
            ForTypeInEnvironment<P, (Any) -> PosterStyleEnvironment>.SetValue(
                { existing in { p in style(existing?(p as! P) ?? .default, p as! P) } },
                for: \.posterStyleRegistry
            )
        )
    }
}
