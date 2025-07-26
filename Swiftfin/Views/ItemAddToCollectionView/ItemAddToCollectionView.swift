//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

struct ItemAddToCollectionView: View {

    // MARK: - Active User Session

    @Injected(\.currentUserSession)
    private var userSession

    // MARK: - Environment & State Variables

    @Router
    private var router

    @StateObject
    private var viewModel: CollectionEditorViewModel

    // MARK: - Media Item

    let item: BaseItemDto

    // MARK: - New Collection Variables

    @State
    private var collectionName: String = ""
    @State
    private var searchForMetadata: Bool = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Computed Variables

    // MARK: Selected Collection Binding

    private var selectedCollectionBinding: Binding<BaseItemDto?> {
        Binding(
            get: { selectedCollection },
            set: { newValue in
                selectedCollection = newValue
            }
        )
    }

    @State
    private var selectedCollection: BaseItemDto?

    // MARK: Valid State

    private var isValid: Bool {
        !(selectedCollection == nil && collectionName.isEmpty)
    }

    // MARK: - Initializer

    init(item: BaseItemDto) {
        self.item = item
        self._viewModel = StateObject(wrappedValue: .init())
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .refreshing:
                ProgressView()
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.update) {
                ProgressView()
            }
            Button(L10n.add) {
                if let itemID = item.id {
                    if selectedCollection == nil {
                        viewModel.send(.createCollection(collectionName, items: [itemID], search: searchForMetadata))
                    } else if let collectionID = selectedCollection?.id {
                        viewModel.send(.addItem(collectionID: collectionID, items: [itemID]))
                    }
                }
            }
            .buttonStyle(.toolbarPill)
            .disabled(!isValid)
        }
        .navigationBarTitle("L10n.addToCollection.localizedCapitalized")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .onFirstAppear {
            Task { @MainActor in
                viewModel.send(.refresh)
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                router.dismiss()
            case let .error(eventError):
                error = eventError
            }
        }
        .errorMessage($error)
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            collectionPickerView

            collectionDetailsView
        }
    }

    // MARK: - Collection Picker View

    private var collectionPickerView: some View {
        Section(L10n.collection) {
            Picker(L10n.collection, selection: selectedCollectionBinding) {
                Text(L10n.add)
                    .tag(nil as BaseItemDto?)

                ForEach(viewModel.collections) { collection in
                    Text(collection.name ?? L10n.unknown)
                        .tag(collection as BaseItemDto?)
                }
            }

            if selectedCollection == nil {
                Toggle(L10n.refreshMetadata, isOn: $searchForMetadata)
            }
        }
    }

    // MARK: - Collection Details View

    @ViewBuilder
    private var collectionDetailsView: some View {
        if let selectedCollection = selectedCollection {

            AdminDashboardView.MediaItemSection(item: selectedCollection)
                .id(selectedCollection.id)

            if let overview = selectedCollection.overview {
                Section(L10n.overview) {
                    Text(overview)
                }
            }
        } else {
            Section(L10n.name) {
                TextField(L10n.name, text: $collectionName)
            }
        }
    }
}
