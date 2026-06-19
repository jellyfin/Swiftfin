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
    private var input: ItemComponentEditorInput = .init(
        id: nil,
        name: "",
        personKind: .unknown,
        personRole: ""
    )

    private var alreadyOnItem: Bool {
        input.name.isNotEmpty && viewModel.editor.containsElement(named: input.name, in: viewModel.item)
    }

    private var existsOnServer: Bool {
        input.name.isNotEmpty && viewModel.editor.matchExists(named: input.name, in: viewModel.matches)
    }

    private var isValid: Bool {
        input.name.isNotEmpty && !alreadyOnItem
    }

    var body: some View {
        List {
            ItemElementSearchView(
                input: $input,
                editor: viewModel.editor,
                population: viewModel.matches,
                isSearching: viewModel.background.states.contains(.searching),
                alreadyOnItem: alreadyOnItem,
                existsOnServer: existsOnServer
            )
        }
        .navigationTitle(viewModel.editor.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.states.contains(where: { $0 == .searching || $0 == .updating }) {
                ProgressView()
            }

            Button(L10n.save) {
                viewModel.add([viewModel.editor.makeElement(input: input)])
            }
            .buttonStyle(.toolbarPill)
            .enabled(isValid)
        }
        .onChange(of: input.name) { newName in
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
