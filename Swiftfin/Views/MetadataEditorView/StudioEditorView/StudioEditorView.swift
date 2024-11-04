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

    @ObservedObject
    private var viewModel: UpdateMetadataViewModel

    @State
    var studios: [NameGuidPair]

    @State
    private var newNameText: String = ""

    init(item: BaseItemDto) {
        self.viewModel = UpdateMetadataViewModel(item: item)
        _tempItem = State(initialValue: item)
        _studios = State(initialValue: item.studios ?? [])
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        contentView
            .navigationBarTitle("Edit People", displayMode: .inline)
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

    // MARK: - Content View

    var contentView: some View {
        List {
            ForEach(studios.indices, id: \.self) { index in
                HStack {
                    VStack(alignment: .leading) {
                        TextField(L10n.studio, text: Binding(
                            get: { studios[index].name ?? "" },
                            set: { studios[index].name = $0 }
                        ))
                    }

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
                TextField("New \(L10n.studio)", text: $newNameText)
                    .onSubmit { addItem() }

                Button(action: addItem) {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newNameText.isEmpty)
            }
        }
        .environment(\.editMode, .constant(.active))
    }

    // MARK: - Add a New Item

    private func addItem() {
        guard !newNameText.isEmpty else { return }
        let newItem = NameGuidPair(name: newNameText)
        studios.append(newItem)
        newNameText = ""
    }

    // MARK: - Delete an Item

    private func deleteItem(at index: Int) {
        studios.remove(at: index)
    }

    // MARK: - Move an Item

    private func moveItems(from source: IndexSet, to destination: Int) {
        studios.move(fromOffsets: source, toOffset: destination)
    }
}
