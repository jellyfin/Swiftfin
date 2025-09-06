//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct ItemAddToCollectionView: View {

    // MARK: - Accent Color

    @Default(.accentColor)
    private var accentColor

    // MARK: - Environment & State Variables

    @Router
    private var router

    @StateObject
    private var viewModel: CollectionEditorViewModel

    // MARK: - Media Item

    let item: BaseItemDto

    // MARK: - New Collection Variables

    @State
    private var selectedCollection: BaseItemDto?
    @State
    private var collectionName: String = ""
    @State
    private var searchForMetadata: Bool = false

    // MARK: - Error State

    @State
    private var error: Error?

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
            BlurView()
                .ignoresSafeArea()
            contentView
        }
        .navigationTitle("L10n.addToCollection.localizedCapitalized")
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.update) {
                ProgressView()
            }
        }
        .onFirstAppear {
            viewModel.send(.refresh)
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

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .initial, .refreshing:
            ProgressView()
        case .content:
            collectionView
        case let .error(error):
            ErrorView(error: error)
        }
    }

    // MARK: - Collection View

    private var collectionView: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "rectangle.stack.badge.plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                collectionPickerSection
                collectionDetailsSection
                actionSection
            }
    }

    // MARK: - Collection Picker Section

    @ViewBuilder
    private var collectionPickerSection: some View {
        Section(L10n.collection) {
            ListRowMenu(L10n.collection) {
                if let selectedCollection {
                    Text(selectedCollection.displayTitle)
                } else {
                    Label(L10n.add, systemImage: "plus")
                }
            } content: {
                Picker(L10n.collection, selection: $selectedCollection) {
                    Text(L10n.add)
                        .tag(nil as BaseItemDto?)

                    ForEach(viewModel.collections) { collection in
                        Text(collection.name ?? L10n.unknown)
                            .tag(collection as BaseItemDto?)
                    }
                }
            }

            if selectedCollection == nil {
                Toggle(L10n.refreshMetadata, isOn: $searchForMetadata)
            }
        }
    }

    // MARK: - Collection Details Section

    @ViewBuilder
    private var collectionDetailsSection: some View {
        if let selectedCollection = selectedCollection {
            mediaItemSection(item: selectedCollection)
                .id(selectedCollection.id)

            if let overview = selectedCollection.overview {
                Section(L10n.overview) {
                    Text(overview)
                }
            }
        } else {
            Section(L10n.name) {
                TextField(L10n.name, text: $collectionName)
                    .listRowInsets(.zero)
            }
        }
    }

    // MARK: - Action Section

    private var actionSection: some View {
        Section {
            ListRowButton(L10n.add) {
                guard let itemID = item.id else { return }

                if selectedCollection == nil {
                    viewModel.send(.createCollection(collectionName, items: [itemID], search: searchForMetadata))
                } else if let collectionID = selectedCollection?.id {
                    viewModel.send(.addItem(collectionID: collectionID, items: [itemID]))
                }
            }
            .foregroundStyle(
                accentColor.overlayColor,
                accentColor
            )
            .listRowInsets(.zero)
            .disabled(!isValid)
            .opacity(isValid ? 1 : 0.5)
        }
    }

    // MARK: - Collection Poster & Details

    private func mediaItemSection(item: BaseItemDto) -> some View {
        Section {
            HStack(alignment: .bottom, spacing: 12) {
                ZStack {
                    Color.clear

                    ImageView(item.portraitImageSources(maxWidth: 200, quality: 90))
                        .failure {
                            SystemImageContentView(systemName: item.systemImage)
                        }
                }
                .posterStyle(.portrait)
                .frame(width: 200)
                .accessibilityIgnoresInvertColors()

                VStack(alignment: .leading) {

                    if let parent = item.parentTitle {
                        Text(parent)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Text(item.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom)
            }
        }
        .listRowBackground(Color.clear)
    }
}
