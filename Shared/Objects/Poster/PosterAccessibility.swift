//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct PosterAccessibility {

    let label: String
    let value: String

    init(label: String, value: String = "") {
        let label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        self.label = label.isEmpty ? L10n.unknown : label
        self.value = value
    }

    static func joined(_ components: [String?]) -> String {
        var values: [String] = []
        for component in components {
            guard let component = component?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !component.isEmpty,
                  !values.contains(component)
            else { continue }
            values.append(component)
        }
        return values.joined(separator: ", ")
    }

    static func duration(_ duration: Duration) -> String {
        duration.formatted(.units(allowed: [.hours, .minutes, .seconds], width: .wide))
    }
}

private struct PosterAccessibilityModifier<Item: Poster>: ViewModifier {

    @Environment(\.posterConfiguration)
    private var posterConfiguration

    @Environment(\.isSelected)
    private var isSelected

    let item: Item

    func body(content: Content) -> some View {
        let description = item.posterAccessibility(configuration: posterConfiguration)

        content
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(description.label)
            .accessibilityValue(description.value)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension View {

    /// For buttons, apply to the label to preserve native button actions and traits.
    func posterAccessibility(for item: some Poster) -> some View {
        modifier(PosterAccessibilityModifier(item: item))
    }
}
