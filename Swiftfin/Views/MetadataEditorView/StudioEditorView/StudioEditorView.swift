//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct StudioEditorView: View {

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @State
    private var tempItem: BaseItemDto
    @State
    private var newNameText: String = ""

    @ObservedObject
    private var viewModel: UpdateMetadataViewModel

    init(item: BaseItemDto) {
        self.viewModel = UpdateMetadataViewModel(item: item)
        _tempItem = State(initialValue: item)
    }

    // MARK: - Body

    var body: some View {
        List {
            ForEach(tempItem.studios?.indices ?? [].indices, id: \.self) { index in
                HStack {
                    TextField(L10n.studio, text: Binding(
                        get: { tempItem.studios?[index].name ?? "" },
                        set: { tempItem.studios?[index].name = $0 }
                    ))
                }
                .swipeActions {
                    Button(role: .destructive) {
                        deleteItem(at: index)
                    } label: {
                        Label(L10n.delete, systemImage: "trash")
                    }
                }
            }
            addNewItemRow
        }
        .navigationTitle(L10n.editWithItem(L10n.studios))
        .navigationBarTitleDisplayMode(.inline)
        .topBarTrailing {
            Button(L10n.save) {
                viewModel.send(.update(tempItem))
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.item == tempItem)
        }
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }

    // MARK: - Add New Item Row

    private var addNewItemRow: some View {
        HStack {
            TextField(L10n.newWithItem(L10n.studio), text: $newNameText)
                .onSubmit { addItem() }
            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
            }
            .disabled(newNameText.isEmpty)
        }
    }

    // MARK: - Add a New Item

    private func addItem() {
        guard !newNameText.isEmpty else { return }
        let newItem = NameGuidPair(name: newNameText)
        if tempItem.studios == nil {
            tempItem.studios = []
        }
        tempItem.studios?.append(newItem)
        newNameText = ""
    }

    // MARK: - Delete an Item

    private func deleteItem(at index: Int) {
        tempItem.studios?.remove(at: index)
    }
}
