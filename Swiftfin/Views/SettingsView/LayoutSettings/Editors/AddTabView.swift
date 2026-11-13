//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AddTabView: View {

    @Binding
    var configuration: LayoutConfiguration
    let isAdministrator: Bool

    @Router
    private var router

    private func addTab(_ destination: TabDestination) {
        if configuration.addTab(destination: destination) {
            router.dismiss()
        }
    }

    private func row(_ destination: TabDestination) -> some View {
        let tab = TabConfiguration(destination: destination)

        return Button {
            addTab(destination)
        } label: {
            Label(configuration.title(for: tab), systemImage: configuration.icon(for: tab))
        }
        .foregroundStyle(.primary)
        .disabled(!configuration.canAddTab(destination: destination))
    }

    private func chooseItem() {
        let existingItemIDs = Set(configuration.tabs.compactMap { tab -> String? in
            guard case let .item(item) = tab.destination else { return nil }

            return item.id
        })

        router.route(to: NavigationRoute(id: "layout-tab-item") {
            LayoutItemPickerView(
                selectionID: nil,
                includedItemTypes: LayoutItemTypes.all,
                nilSelectionTitle: nil,
                title: L10n.items,
                disabledItemIDs: existingItemIDs,
                dismissOnSelect: false
            ) { item in
                guard let item else { return }

                addTab(.item(ItemReference(item: item)))
            }
        })
    }

    @ContentBuilder
    var body: some View {
        Form(systemImage: "plus") {
            Section {
                ForEach(TabDestination.presets(isAdministrator: isAdministrator), id: \.self) { row($0) }
            }

            Section {
                ChevronButton(L10n.items, systemName: "rectangle.stack", action: chooseItem)
                    .disabled(!configuration.canAddTab)
            }

            if configuration.views.isNotEmpty {
                Section(L10n.userViews) {
                    ForEach(configuration.views) { view in
                        row(.contentView(id: view.id))
                    }
                }
            }
        }
        .navigationTitle(L10n.addTab)
        .navigationBarCloseButton { router.dismiss() }
    }
}
