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

struct AddTagView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @FocusState
    private var focusedField: Bool

    @ObservedObject
    var viewModel: TagEditorViewModel

    @State
    private var name: String = ""

    @State
    private var isServerTag: Bool?

    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

    private var isValid: Bool {
        !name.isEmpty
    }

    // MARK: - Body

    var body: some View {
        contentView
            .animation(.linear(duration: 0.2), value: isValid)
            .interactiveDismissDisabled(viewModel.backgroundStates.contains(.refreshing))
            .navigationTitle(L10n.tags)
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
                    isServerTag = eventTags.isNotEmpty
                case let .error(eventError):
                    if eventError != JellyfinAPIError("cancelled") {
                        UIDevice.feedback(.error)
                        error = eventError
                        isPresentingError = true
                    }
                }
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
                if name.isNotEmpty && !viewModel.backgroundStates.contains(.refreshing) {
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
                    .focused($focusedField)
                    .disabled(viewModel.state == .updating)
            } header: {
                Text(L10n.name)
            } footer: {
                if name.isEmpty {
                    Label(L10n.required, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else if let tagOnServer = isServerTag {
                    if tagOnServer {
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
            }
        }
    }
}
