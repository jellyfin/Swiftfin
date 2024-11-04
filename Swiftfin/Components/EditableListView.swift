//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EditableListView: View {
    let title: String

    @Binding
    var items: [String]

    @State
    private var newItemText: String = ""

    // MARK: - Body

    var body: some View {
        List {
            ForEach(items.indices, id: \.self) { index in
                HStack {
                    TextField(title, text: Binding(
                        get: { items[index] },
                        set: { items[index] = $0 }
                    ))

                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.secondary)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        deleteItem(at: index)
                    } label: {
                        Label(L10n.delete, systemImage: "trash")
                    }
                }
            }
            .onMove(perform: moveItems)

            HStack {
                TextField("New \(title)", text: $newItemText)
                    .onSubmit {
                        addItem()
                    }
                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newItemText.isEmpty)
            }
        }
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Add a New Item

    private func addItem() {
        guard !newItemText.isEmpty else { return }
        items.append(newItemText)
        newItemText = ""
    }

    // MARK: - Delete an Item

    private func deleteItem(at index: Int) {
        items.remove(at: index)
    }

    // MARK: - Move an Item

    private func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}
