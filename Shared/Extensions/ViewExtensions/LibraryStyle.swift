//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LibraryStyle: Hashable, Storable, WithDefaultValue {

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
    var libraryStyleRegistry: TypeKeyedDictionary<(Any) -> (LibraryStyle, Binding<LibraryStyle>?)> = .init()
}

extension View {

    @ViewBuilder
    func libraryStyle<V>(
        for type: V,
        style: @escaping ((LibraryStyle, Binding<LibraryStyle>?), V) -> (LibraryStyle, Binding<LibraryStyle>?)
    ) -> some View {
        modifier(
            ForTypeInEnvironment<V, (Any) -> (LibraryStyle, Binding<LibraryStyle>?)>.SetValue(
                { existing in
                    { value in
                        style(existing?(value as! V) ?? (.default, nil), value as! V)
                    }
                },
                for: \.libraryStyleRegistry
            )
        )
    }
}
