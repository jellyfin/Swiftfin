//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct AddGenreView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @FocusState
    private var focusedField: Bool

    @ObservedObject
    var viewModel: GenreEditorViewModel

    @State
    private var name: String = ""
    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

    // MARK: - Name is Valid

    private var isValid: Bool {
        name.isNotEmpty
    }

    // MARK: - Data is Updating

    private var isUpdating: Bool {
        viewModel.state == .updating
    }

    // MARK: - Body

    var body: some View {
        contentView
            .animation(.linear(duration: 0.2), value: isValid)
            .navigationTitle(L10n.genres)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.refreshing) {
                    ProgressView()
                }

                Button(L10n.save) {
                    viewModel.send(.add([name]))
                }
                .buttonStyle(.toolbarPill)
                .disabled(!isValid)
            }
            .onFirstAppear {
                viewModel.send(.refresh)
            }
            .onChange(of: name) { _ in
                if isValid {
                    viewModel.send(.getSuggestions(name))
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
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
            ) { _ in
                Button(L10n.dismiss, role: .cancel) {
                    focusedField = true
                }
            } message: { error in
                Text(error.localizedDescription)
            }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            ItemEditorView.NameInput(
                name: $name,
                suggestions: viewModel.suggestions
            )
            ItemEditorView.SuggestionsSection(
                name: $name,
                suggestions: viewModel.suggestions
            )
        }
    }
}
