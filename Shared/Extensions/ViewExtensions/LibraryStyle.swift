//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LibraryStyle: WithDefaultValue, Hashable, Storable {

    var displayType: LibraryDisplayType
    var posterDisplayType: PosterDisplayType
    var listColumnCount: Int

    static let `default`: LibraryStyle = .init(
        displayType: .grid,
        posterDisplayType: .portrait,
        listColumnCount: 1
    )
}

extension EnvironmentValues {

    @Entry
    var libraryStyleRegistry: TypeKeyedDictionary<(Any) -> (
        LibraryStyle,
        Binding<LibraryStyle>?
    )> = .init()
}

extension View {

    @ViewBuilder
    func libraryStyle<V>(
        for type: V,
        source: Binding<LibraryStyle>,
        style: @escaping (V) -> (LibraryStyle, Binding<LibraryStyle>)
    ) -> some View {
        libraryStyle(for: type) { _, v in
            style(v)
        }
    }

    @ViewBuilder
    func libraryStyle<V>(
        for type: V,
        style: @escaping ((LibraryStyle, Binding<LibraryStyle>?), V) -> (
            LibraryStyle,
            Binding<LibraryStyle>?
        )
    ) -> some View {
        modifier(
            ForTypeInEnvironment<V, (Any) -> (LibraryStyle, Binding<LibraryStyle>?)>.SetValue(
                { existing in { v in style(existing?(v as! V) ?? (.default, nil), v as! V) } },
                for: \.libraryStyleRegistry
            )
        )
    }
}
