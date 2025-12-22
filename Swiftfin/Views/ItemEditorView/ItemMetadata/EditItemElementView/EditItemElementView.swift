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

// TODO: move away from the `route` method for adding a new item
struct EditItemElementView<Element: Hashable>: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var viewModel: ItemEditorViewModel<Element>

    @Router
    private var router

    @State
    private var elements: [Element]
    @State
    private var selectedElements: Set<Element> = []
    @State
    private var isEditing: Bool = false
    @State
    private var isReordering: Bool = false
    @State
    private var isPresentingDeletionConfirmation = false

    private let type: ItemArrayElements
    private let route: (NavigationCoordinator.Router, ItemEditorViewModel<Element>) -> Void

    init(
        viewModel: ItemEditorViewModel<Element>,
        type: ItemArrayElements,
        route: @escaping (NavigationCoordinator.Router, ItemEditorViewModel<Element>) -> Void
    ) {
        self.viewModel = viewModel
        self.type = type
        self.route = route
        self.elements = type.getElement(for: viewModel.item)
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(type.displayTitle)
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
                        Button(L10n.cancel) {
                            if isEditing {
                                isEditing.toggle()
                            }
                            if isReordering {
                                elements = type.getElement(for: viewModel.item)
                                isReordering.toggle()
                            }
                            UIDevice.impact(.light)
                            selectedElements.removeAll()
                        }
                        .buttonStyle(.toolbarPill)
                        .foregroundStyle(accentColor)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    if isEditing {
                        Button(L10n.delete) {
                            isPresentingDeletionConfirmation = true
                        }
                        .buttonStyle(.toolbarPill(.red))
                        .disabled(selectedElements.isEmpty)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    if isReordering {
                        Button(L10n.save) {
                            viewModel.reorder(elements)
                            isReordering = false
                        }
                        .buttonStyle(.toolbarPill)
                        .disabled(type.getElement(for: viewModel.item) == elements)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .navigationBarMenuButton(
                isLoading: viewModel.background.states.contains(where: { $0 == .searching || $0 == .updating }),
                isHidden: isEditing || isReordering
            ) {
                Button(L10n.add, systemImage: "plus") {
                    route(router.router, viewModel)
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
                elements = type.getElement(for: viewModel.item)
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .deleted, .metadataRefreshStarted:
                    break
                case .updated:
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

    // MARK: - Select/Remove All Button

    @ViewBuilder
    private var navigationBarSelectView: some View {
        let isAllSelected = selectedElements.count == (elements.count)
        Button(isAllSelected ? L10n.removeAll : L10n.selectAll) {
            selectedElements = isAllSelected ? [] : Set(elements)
        }
        .buttonStyle(.toolbarPill)
        .disabled(!isEditing)
        .foregroundStyle(accentColor)
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            InsetGroupedListHeader(type.displayTitle, description: type.description)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, 24)

            if elements.isNotEmpty {
                ForEach(elements, id: \.self) { element in
                    EditItemElementRow(
                        item: element,
                        type: type,
                        onSelect: {
                            if isEditing {
                                selectedElements.toggle(value: element)
                            }
                        },
                        onDelete: {
                            selectedElements.toggle(value: element)
                            isPresentingDeletionConfirmation = true
                        }
                    )
                    .isEditing(isEditing)
                    .isSelected(selectedElements.contains(element))
                    .listRowInsets(.edgeInsets)
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
}
