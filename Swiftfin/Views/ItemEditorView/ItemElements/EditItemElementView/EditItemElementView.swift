//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct EditItemElementView<Element: Hashable>: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: ItemEditorCoordinator.Router

    @ObservedObject
    var viewModel: ItemEditorViewModel<Element>

    // MARK: - Elements

    @State
    private var elements: [Element]

    // MARK: - Type & Route

    private let type: ItemArrayElements
    private let route: (ItemEditorCoordinator.Router, ItemEditorViewModel<Element>) -> Void

    // MARK: - Dialog States

    @State
    private var isPresentingDeleteConfirmation = false
    @State
    private var isPresentingDeleteSelectionConfirmation = false

    // MARK: - Editing States

    @State
    private var selectedElements: Set<Element> = []
    @State
    private var isEditing: Bool = false
    @State
    private var isReordering: Bool = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(
        viewModel: ItemEditorViewModel<Element>,
        type: ItemArrayElements,
        route: @escaping (ItemEditorCoordinator.Router, ItemEditorViewModel<Element>) -> Void
    ) {
        self.viewModel = viewModel
        self.type = type
        self.route = route
        self.elements = type.getElement(for: viewModel.item)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .content, .updating:
                contentView
            case let .error(error):
                errorView(with: error)
            }
        }
        .navigationBarTitle(type.displayTitle)
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
                        isPresentingDeleteSelectionConfirmation = true
                    }
                    .buttonStyle(.toolbarPill(.red))
                    .disabled(selectedElements.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                if isReordering {
                    Button(L10n.save) {
                        viewModel.send(.reorder(elements))
                        isReordering = false
                    }
                    .buttonStyle(.toolbarPill)
                    .disabled(type.getElement(for: viewModel.item) == elements)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .navigationBarMenuButton(
            isLoading: viewModel.backgroundStates.contains(.refreshing),
            isHidden: isEditing || isReordering
        ) {
            Button(L10n.add, systemImage: "plus") {
                route(router, viewModel)
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
        .onReceive(viewModel.events) { events in
            switch events {
            case let .error(eventError):
                error = eventError
            default:
                break
            }
        }
        .errorMessage($error)
        .confirmationDialog(
            L10n.delete,
            isPresented: $isPresentingDeleteSelectionConfirmation,
            titleVisibility: .visible
        ) {
            deleteSelectedConfirmationActions
        } message: {
            Text(L10n.deleteSelectedConfirmation)
        }
        .confirmationDialog(
            L10n.delete,
            isPresented: $isPresentingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            deleteConfirmationActions
        } message: {
            Text(L10n.deleteItemConfirmation)
        }
        .onNotification(.itemMetadataDidChange) { _ in
            self.elements = type.getElement(for: self.viewModel.item)
        }
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

    // MARK: - ErrorView

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.load)
            }
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
                            isPresentingDeleteConfirmation = true
                        }
                    )
                    .environment(\.isEditing, isEditing)
                    .environment(\.isSelected, selectedElements.contains(element))
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

    // MARK: - Delete Selected Confirmation Actions

    @ViewBuilder
    private var deleteSelectedConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.confirm, role: .destructive) {
            let elementsToRemove = elements.filter { selectedElements.contains($0) }
            viewModel.send(.remove(elementsToRemove))
            selectedElements.removeAll()
            isEditing = false
        }
    }

    // MARK: - Delete Single Confirmation Actions

    @ViewBuilder
    private var deleteConfirmationActions: some View {
        Button(L10n.cancel, role: .cancel) {}

        Button(L10n.delete, role: .destructive) {
            if let elementToRemove = selectedElements.first, selectedElements.count == 1 {
                viewModel.send(.remove([elementToRemove]))
                selectedElements.removeAll()
                isEditing = false
            }
        }
    }
}
