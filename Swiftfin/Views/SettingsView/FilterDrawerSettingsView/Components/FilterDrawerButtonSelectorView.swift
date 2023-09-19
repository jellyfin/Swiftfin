//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: Look at moving across sections
// TODO: Look at general implementation in SelectorView
struct FilterDrawerButtonSelectorView: View {

    @Binding
    var selectedButtonsBinding: [FilterDrawerButtonSelection]

    @Environment(\.editMode)
    private var editMode

    @State
    private var _selectedButtons: [FilterDrawerButtonSelection]

    private var disabledButtons: [FilterDrawerButtonSelection] {
        FilterDrawerButtonSelection.allCases.filter { !_selectedButtons.contains($0) }
    }

    var body: some View {
        List {
            Section {
                ForEach(_selectedButtons) { item in
                    Button {
                        if !(editMode?.wrappedValue.isEditing ?? true) {
                            select(item: item)
                        }
                    } label: {
                        HStack {
                            Text(item.displayTitle)

                            Spacer()

                            if !(editMode?.wrappedValue.isEditing ?? false) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                .onMove(perform: move)

                if _selectedButtons.isEmpty {
                    Text("None")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Enabled")
            }

            Section {
                ForEach(disabledButtons) { item in
                    Button {
                        if !(editMode?.wrappedValue.isEditing ?? true) {
                            select(item: item)
                        }
                    } label: {
                        HStack {
                            Text(item.displayTitle)

                            Spacer()

                            if !(editMode?.wrappedValue.isEditing ?? false) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                if disabledButtons.isEmpty {
                    Text("None")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Disabled")
            }
        }
        .animation(.linear(duration: 0.2), value: _selectedButtons)
        .toolbar {
            EditButton()
        }
        .onChange(of: _selectedButtons) { newValue in
            selectedButtonsBinding = newValue
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        _selectedButtons.move(fromOffsets: source, toOffset: destination)
    }

    private func select(item: FilterDrawerButtonSelection) {
        if _selectedButtons.contains(item) {
            _selectedButtons.removeAll(where: { $0.id == item.id })
        } else {
            _selectedButtons.append(item)
        }
    }
}

extension FilterDrawerButtonSelectorView {

    init(selectedButtonsBinding: Binding<[FilterDrawerButtonSelection]>) {
        self.init(
            selectedButtonsBinding: selectedButtonsBinding,
            _selectedButtons: selectedButtonsBinding.wrappedValue
        )
//        self._selectedButtonsBinding = selectedButtonsBinding
//        self._selectedButtons = selectedButtonsBinding.wrappedValue
    }
}
