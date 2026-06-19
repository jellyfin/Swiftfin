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

struct AddItemElementView<Editor: ItemComponentEditor>: View {

    @ObservedObject
    var viewModel: ItemComponentEditorViewModel<Editor>

    @Router
    private var router

    @State
    private var id: String?
    @State
    private var name: String = ""
    @State
    private var personKind: PersonKind = .unknown
    @State
    private var personRole: String = ""

    @State
    private var error: Error?

    // MARK: - Validation

    private var alreadyOnItem: Bool {
        name.isNotEmpty && viewModel.containsElement(named: name)
    }

    private var existsOnServer: Bool {
        name.isNotEmpty && viewModel.matchExists(named: name)
    }

    private var isValid: Bool {
        name.isNotEmpty && !alreadyOnItem
    }

    // MARK: - Body

    var body: some View {
        List {
            ItemElementSearchView(
                name: $name,
                id: $id,
                supportsPeopleFields: viewModel.supportsPeopleFields,
                personKind: $personKind,
                personRole: $personRole,
                population: viewModel.matches,
                isSearching: viewModel.background.states.contains(.searching),
                alreadyOnItem: alreadyOnItem,
                existsOnServer: existsOnServer,
                idForElement: viewModel.id(for:),
                nameForElement: viewModel.name(for:)
            )
        }
        .navigationTitle(viewModel.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.states.contains(where: { $0 == .searching || $0 == .updating }) {
                ProgressView()
            }

            Button(L10n.save) {
                viewModel.add([viewModel.makeElement(input: .init(
                    id: id,
                    name: name,
                    personKind: personKind,
                    personRole: personRole
                ))])
            }
            .buttonStyle(.toolbarPill)
            .enabled(isValid)
        }
        .onChange(of: name) { newName in
            viewModel.search(newName)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
    }
}
