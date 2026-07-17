//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: Only have people have .plain style, grouped for normal text

struct EditItemElementView<Editor: ItemComponentEditor>: View {

    @ObservedObject
    private var viewModel: ItemComponentEditorViewModel<Editor>

    @Router
    private var router

    @State
    private var elements: [Editor.Element]
    @State
    private var selectedElements: Set<Editor.Element> = []
    @State
    private var isEditing: Bool = false
    @State
    private var isReordering: Bool = false
    @State
    private var isPresentingDeletionConfirmation = false

    init(viewModel: ItemComponentEditorViewModel<Editor>) {
        self.viewModel = viewModel
        self.elements = viewModel.editor.elements(in: viewModel.item)
    }

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected = selectedElements.count == (elements.count)
        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            selectedElements = isAllSelected ? [] : Set(elements)
        }
        .foregroundStyle(.primary, .secondary)
        .backport
        .buttonStyle(.glass)
        .controlSize(.small)
        .disabled(!isEditing)
    }

    @ViewBuilder
    private var contentView: some View {
        List {
            InsetGroupedListHeader(viewModel.editor.displayTitle, description: viewModel.editor.description)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, 24)

            if elements.isNotEmpty {
                ForEach(elements, id: \.self) { element in
                    element.makeBody(
                        libraryStyle: .init(displayType: .list, posterDisplayType: .portrait, listColumnCount: 1),
                        action: {
                            if isEditing {
                                selectedElements.toggle(value: element)
                            }
                        }
                    )
                    .isEditing(isEditing)
                    .isSelected(selectedElements.contains(element))
                    .listRowInsets(.edgeInsets)
                    .swipeActions {
                        Button(
                            L10n.delete,
                            systemImage: "trash"
                        ) {
                            selectedElements.toggle(value: element)
                            isPresentingDeletionConfirmation = true
                        }
                        .tint(.red)
                    }
                }
                .onMove { source, destination in
                    guard isReordering else { return }
                    elements.move(fromOffsets: source, toOffset: destination)
                }
            } else {
                Text(L10n.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.zero)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, isReordering ? .constant(.active) : .constant(.inactive))
    }

    var body: some View {
        contentView
            .navigationTitle(viewModel.editor.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isEditing || isReordering)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        navigationBarSelectView
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing || isReordering {
                        Button(L10n.cancel, role: .cancel) {
                            if isEditing {
                                isEditing.toggle()
                            }

                            if isReordering {
                                elements = viewModel.editor.elements(in: viewModel.item)
                                isReordering.toggle()
                            }

                            UIDevice.impact(.light)
                            selectedElements.removeAll()
                        }
                        .foregroundStyle(.primary, .secondary)
                        .backport
                        .buttonStyle(.glass)
                        .controlSize(.small)
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    if isEditing {
                        Button(L10n.delete, role: .destructive) {
                            isPresentingDeletionConfirmation = true
                        }
                        .backport
                        .buttonStyle(.glassProminent)
                        .disabled(selectedElements.isEmpty)
                    }

                    if isReordering {
                        let saveAction: () -> Void = {
                            viewModel.reorder(elements)
                            isReordering = false
                        }

                        Group {
                            if #available(iOS 26, *), Defaults[.isLiquidGlassEnabled] {
                                Button(L10n.save, role: .confirm, action: saveAction)
                            } else {
                                Button(L10n.save, action: saveAction)
                                    .backport
                                    .buttonStyle(.glassProminent)
                                    .controlSize(.small)
                            }
                        }
                        .disabled(viewModel.editor.elements(in: viewModel.item) == elements)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .navigationBarMenuButton(
                isLoading: viewModel.background.states.contains(where: { $0 == .searching || $0 == .updating }),
                isHidden: isEditing || isReordering
            ) {
                Button(L10n.add, systemImage: "plus") {
                    router.route(to: .addItemElement(viewModel: viewModel))
                }

                if elements.isNotEmpty == true {
                    Button(L10n.edit, systemImage: "checkmark.circle") {
                        isEditing = true
                    }

                    Button(L10n.reorder, systemImage: "arrow.up.arrow.down") {
                        isReordering = true
                    }
                }
            }
            .onNotification(.itemMetadataDidChange) { _ in
                elements = viewModel.editor.elements(in: viewModel.item)
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .updated:
                    elements = viewModel.editor.elements(in: viewModel.item)
                    UIDevice.feedback(.success)
                }
            }
            .confirmationDialog(
                L10n.delete,
                isPresented: $isPresentingDeletionConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.cancel, role: .cancel) {}

                Button(L10n.confirm, role: .destructive) {
                    let elementsToRemove = elements.filter { selectedElements.contains($0) }
                    viewModel.remove(elementsToRemove)
                    selectedElements.removeAll()
                    isEditing = false
                }
            } message: {
                Text(L10n.deleteSelectedConfirmation)
            }
            .errorMessage($viewModel.error)
    }
}
