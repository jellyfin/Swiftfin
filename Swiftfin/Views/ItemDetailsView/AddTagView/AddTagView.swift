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
    var viewModel: ItemTagsViewModel

    @State
    private var name: String = ""

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
            .interactiveDismissDisabled(viewModel.state == .refreshing)
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
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                    isPresentingError = true
                }
            }
            .topBarTrailing {
                if viewModel.state == .refreshing {
                    ProgressView()
                }

                Button(L10n.save) {
                    createTag()
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
    }

    // MARK: - Content View

    private var contentView: some View {
        List {
            Section {
                TextField(L10n.name, text: $name)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .focused($focusedField)
                    .disabled(viewModel.state == .refreshing)
            } header: {
                Text(L10n.name)
            } footer: {
                if name.isEmpty {
                    Label(L10n.required, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }
        }
    }

    // MARK: - Create Genre Action

    private func createTag() {
        viewModel.send(.add([name]))
    }
}
