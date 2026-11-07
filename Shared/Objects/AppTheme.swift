//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@propertyWrapper
struct AppTheme: DynamicProperty {

    struct Value: Equatable {

        var appearance: AppAppearance = .system
        var accentColor: Color = .jellyfinPurple

        func resolved(colorScheme: ColorScheme, contrast: ColorSchemeContrast) -> Value {
            Value(
                appearance: appearance,
                accentColor: contrast == .increased ? accentColor.mix(
                    with: colorScheme == .dark ? .white : .black,
                    by: 0.25
                ) : accentColor
            )
        }
    }

    @Environment(\.colorScheme)
    private var colorScheme
    @Environment(\EnvironmentValues.colorSchemeContrast as WritableKeyPath<EnvironmentValues, ColorSchemeContrast>)
    private var contrast
    @Environment(\.theme)
    private var theme

    var wrappedValue: Value {
        theme.resolved(colorScheme: colorScheme, contrast: contrast)
    }
}
