//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

final class CustomizeSettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \CustomizeSettingsCoordinator.start)

    @Root
    var start = makeStart

    @Route(.modal)
    var indicatorSettings = makeIndicatorSettings
    @Route(.modal)
    var itemViewAttributes = makeItemViewAttributes
    @Route(.push)
    var listColumnSettings = makeListColumnSettings

    func makeIndicatorSettings() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            IndicatorSettingsView()
        }
    }

    func makeItemViewAttributes(selection: Binding<[ItemViewAttribute]>) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            OrderedSectionSelectorView(selection: selection, sources: ItemViewAttribute.allCases)
                .systemImage("list.bullet.rectangle.fill")
                .navigationTitle(L10n.mediaAttributes.localizedCapitalized)
        }
    }

    @ViewBuilder
    func makeListColumnSettings(selection: Binding<Int>) -> some View {
        ListColumnsPickerView(selection: selection)
    }

    @ViewBuilder
    func makeStart() -> some View {
        CustomizeViewsSettings()
    }
}
