//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct AddItemElementView<Element: Hashable>: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    var viewModel: ItemEditorViewModel<Element>

    let type: ItemArrayElements

    @State
    private var id: String?
    @State
    private var name: String = ""
    @State
    private var personKind: PersonKind = .unknown
    @State
    private var personRole: String = ""

    @State
    private var loaded: Bool = false

    @State
    private var isPresentingError: Bool = false
    @State
    private var error: Error?

    // MARK: - Name is Valid

    private var isValid: Bool {
        name.isNotEmpty
    }

    private var itemAlreadyExists: Bool {
        viewModel.trie.contains(key: name.localizedLowercase)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case let .error(error):
                ErrorView(error: error)
            case .updating:
                DelayedProgressView()
            case .initial, .content:
                contentView
            }
        }
        .navigationTitle(type.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.loading) {
                ProgressView()
            }

            Button(L10n.save) {
                viewModel.send(.add([type.createElement(
                    name: name,
                    id: id,
                    personRole: personRole.isEmpty ? (personKind == .unknown ? nil : personKind.rawValue) : personRole,
                    personKind: personKind.rawValue
                )]))
            }
            .buttonStyle(.toolbarPill)
            .disabled(!isValid)
        }
        .onFirstAppear {
            viewModel.send(.load)
        }
        .onChange(of: name) { _ in
            if !viewModel.backgroundStates.contains(.loading) {
                viewModel.send(.search(name))
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismissCoordinator()
            case .loaded:
                loaded = true
                viewModel.send(.search(name))
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
                isPresentingError = true
            }
        }
        .alert(
            L10n.error,
            isPresented: $isPresentingError,
            presenting: error
        ) { error in
            Text(error.localizedDescription)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            NameInput(
                name: $name,
                type: type,
                personKind: $personKind,
                personRole: $personRole,
                itemAlreadyExists: itemAlreadyExists
            )

            SearchResultsSection(
                id: $id,
                name: $name,
                type: type,
                population: viewModel.matches,
                isSearching: viewModel.backgroundStates.contains(.searching)
            )
        }
    }
}
