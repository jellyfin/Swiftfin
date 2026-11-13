//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Observation
import SwiftUI

@MainActor
@Observable
final class LayoutDraft {

    var configuration: LayoutConfiguration

    init(configuration: LayoutConfiguration) {
        self.configuration = configuration
    }

    func binding<Element: Identifiable>(
        for element: Element,
        in keyPath: WritableKeyPath<LayoutConfiguration, [Element]>
    ) -> Binding<Element> {
        Binding {
            self.configuration[keyPath: keyPath].first { $0.id == element.id } ?? element
        } set: { value in
            guard let index = self.configuration[keyPath: keyPath].firstIndex(where: { $0.id == element.id }) else { return }

            self.configuration[keyPath: keyPath][index] = value
        }
    }

    func binding(
        for group: ContentGroupConfiguration,
        in viewID: ContentViewConfiguration.ID
    ) -> Binding<ContentGroupConfiguration> {
        Binding {
            self.configuration.view(withID: viewID)?.groups.first { $0.id == group.id } ?? group
        } set: { value in
            guard let viewIndex = self.configuration.views.firstIndex(where: { $0.id == viewID }),
                  let groupIndex = self.configuration.views[viewIndex].groups.firstIndex(where: { $0.id == group.id })
            else { return }

            self.configuration.views[viewIndex].groups[groupIndex] = value
        }
    }
}
