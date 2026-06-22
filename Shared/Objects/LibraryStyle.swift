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

struct LibraryStyleOptions: Hashable, WithDefaultValue {

    var displayTypes: [LibraryDisplayType]
    var fallbackPosterDisplayType: PosterDisplayType
    var posterDisplayTypes: [PosterDisplayType]

    static let `default`: Self = .init(
        posterDisplayTypes: PosterDisplayType.allCases,
        fallbackPosterDisplayType: LibraryStyle.default.posterDisplayType
    )

    init(
        displayTypes: [LibraryDisplayType] = LibraryDisplayType.allCases,
        posterDisplayTypes: [PosterDisplayType],
        fallbackPosterDisplayType: PosterDisplayType
    ) {
        self.displayTypes = displayTypes.isEmpty ? LibraryDisplayType.allCases : displayTypes
        self.posterDisplayTypes = posterDisplayTypes.isEmpty ? PosterDisplayType.allCases : posterDisplayTypes
        self.fallbackPosterDisplayType = fallbackPosterDisplayType
    }

    func normalized(_ style: LibraryStyle) -> LibraryStyle {
        var style = style

        if !displayTypes.contains(style.displayType) {
            style.displayType = displayTypes.first ?? LibraryStyle.default.displayType
        }

        if !posterDisplayTypes.contains(style.posterDisplayType) {
            style.posterDisplayType = posterDisplayTypes.contains(fallbackPosterDisplayType) ?
                fallbackPosterDisplayType :
                posterDisplayTypes.first ?? LibraryStyle.default.posterDisplayType
        }

        style.listColumnCount = max(1, style.listColumnCount)

        return style
    }

    func binding(_ binding: Binding<LibraryStyle>) -> Binding<LibraryStyle> {
        Binding {
            normalized(binding.wrappedValue)
        } set: { newValue in
            binding.wrappedValue = normalized(newValue)
        }
    }

    var hasVisibleControls: Bool {
        displayTypes.count > 1 || posterDisplayTypes.count > 1
    }

    static func resolving(
        _ elementOptions: some Sequence<LibraryStyleOptions>,
        fallback: LibraryStyleOptions
    ) -> LibraryStyleOptions {
        let elementOptions = Array(elementOptions)
        guard elementOptions.isNotEmpty else { return fallback }

        let displayTypes = LibraryDisplayType.allCases
            .filter { displayType in
                elementOptions.contains { option in
                    option.displayTypes.contains(displayType)
                }
            }

        let posterDisplayTypes = PosterDisplayType.allCases
            .filter { posterDisplayType in
                elementOptions.contains { option in
                    option.posterDisplayTypes.contains(posterDisplayType)
                }
            }

        let fallbackPosterDisplayType = posterDisplayTypes.contains(fallback.fallbackPosterDisplayType) ?
            fallback.fallbackPosterDisplayType :
            posterDisplayTypes.first ?? LibraryStyle.default.posterDisplayType

        return .init(
            displayTypes: displayTypes,
            posterDisplayTypes: posterDisplayTypes,
            fallbackPosterDisplayType: fallbackPosterDisplayType
        )
    }
}
