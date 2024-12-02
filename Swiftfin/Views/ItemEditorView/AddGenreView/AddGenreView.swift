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
    private var serverGenres: [String] = []

    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

    // MARK: - Name is Valid

    private var isValid: Bool {
        name.isNotEmpty
    }

    // MARK: - Data is Loading

    private var isLoading: Bool {
        !viewModel.backgroundStates.isDisjoint(with: [.refreshing, .searching])
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
            .onFirstAppear {
                focusedField = true
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                case let .searchResults(eventTags):
                    serverGenres = eventTags
                case let .error(eventError):
                    if eventError != JellyfinAPIError("cancelled") {
                        UIDevice.feedback(.error)
                        error = eventError
                        isPresentingError = true
                    }
                }
            }
            .topBarTrailing {
                if isLoading {
                    ProgressView()
                }

                Button(L10n.save) {
                    viewModel.send(.add([name]))
                }
                .buttonStyle(.toolbarPill)
                .disabled(!isValid)
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
            .onChange(of: name) { _ in
                if isValid {
                    viewModel.send(.search(name))
                }
            }
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            Section {
                TextField(L10n.name, text: $name)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .focused($focusedField)
                    .disabled(viewModel.state == .updating)
            } header: {
                Text(L10n.name)
            } footer: {
                if name.isEmpty {
                    Label(L10n.required, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else if serverGenres.contains(name) {
                    Label(
                        L10n.existsOnServer,
                        systemImage: "checkmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .green))
                } else {
                    Label(
                        L10n.willBeCreatedOnServer,
                        systemImage: "checkmark.seal.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .blue))
                }
            }

            if serverGenres.isNotEmpty && isValid {
                Section(L10n.suggestions) {
                    searchView
                }
            }
        }
    }

    private var searchView: some View {
        ForEach(serverGenres, id: \.self) { genre in
            Button(genre) {
                name = genre
            }
            .foregroundStyle(.primary)
            .disabled(name == genre)
        }
    }
}
