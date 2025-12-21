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

struct AddItemElementView<Element: Hashable>: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Environment & Observed Objects

    @Router
    private var router

    @ObservedObject
    var viewModel: ItemEditorViewModel<Element>

    // MARK: - Elements Variables

    let type: ItemArrayElements

    @State
    private var id: String?
    @State
    private var name: String = ""
    @State
    private var personKind: PersonKind = .unknown
    @State
    private var personRole: String = ""

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Name is Valid

    private var isValid: Bool {
        name.isNotEmpty
    }

    // MARK: - Name Already Exists

    private var itemAlreadyExists: Bool {
        let input = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        guard input.isNotEmpty else { return false }

        return viewModel.matches.contains { element in
            let candidate: String?

            switch type {
            case .people:
                candidate = (element as? BaseItemPerson)?.name

            case .genres, .tags:
                if let string = element as? String {
                    candidate = string
                } else if let pair = element as? NameGuidPair {
                    candidate = pair.name
                } else {
                    assertionFailure("Unexpected element type: \(Element.self)")
                    return false
                }

            case .studios:
                candidate = (element as? NameGuidPair)?.name
            }

            guard let value = candidate else { return false }

            let normalized = value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

            return normalized == input
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .initial:
                contentView
            }
        }
        .navigationTitle(type.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.states.contains(where: { $0 == .searching || $0 == .updating }) {
                ProgressView()
            }

            Button(L10n.save) {
                viewModel.add([type.createElement(
                    name: name,
                    id: id,
                    personRole: personRole.isEmpty ? (personKind == .unknown ? nil : personKind.rawValue) : personRole,
                    personKind: personKind
                )])
            }
            .buttonStyle(.toolbarPill)
            .disabled(!isValid)
        }
        .onChange(of: name) { _ in
            viewModel.search(name)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            NameInput(
                name: $name,
                personKind: $personKind,
                personRole: $personRole,
                type: type,
                itemAlreadyExists: itemAlreadyExists
            )

            SearchResultsSection(
                name: $name,
                id: $id,
                type: type,
                population: viewModel.matches,
                isSearching: viewModel.background.states.contains(.searching)
            )
        }
    }
}
