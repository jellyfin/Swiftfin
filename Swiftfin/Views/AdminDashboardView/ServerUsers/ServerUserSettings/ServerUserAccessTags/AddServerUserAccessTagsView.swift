//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AddServerUserAccessTagsView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    @StateObject
    private var tagViewModel: TagEditorViewModel

    @State
    private var tempPolicy: UserPolicy
    @State
    private var tempTag: String = ""
    @State
    private var access: Bool = false

    private var alreadyOnItem: Bool {
        let blocked = tempPolicy.blockedTags ?? []
        let allowed = tempPolicy.allowedTags ?? []
        return blocked.contains { $0.caseInsensitiveCompare(tempTag) == .orderedSame }
            || allowed.contains { $0.caseInsensitiveCompare(tempTag) == .orderedSame }
    }

    private var existsOnServer: Bool {
        tempTag.isNotEmpty && tagViewModel.matchExists(named: tempTag)
    }

    private var isValid: Bool {
        tempTag.isNotEmpty && !alreadyOnItem
    }

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
        self.tempPolicy = viewModel.user.policy ?? UserPolicy(
            authenticationProviderID: "",
            passwordResetProviderID: ""
        )
        self._tagViewModel = StateObject(wrappedValue: TagEditorViewModel(item: .init()))
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.addAccessTag.localizedCapitalized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.refreshing) ||
                    tagViewModel.background.states.contains(.searching)
                {
                    ProgressView()
                }
                if viewModel.backgroundStates.contains(.updating) {
                    Button(L10n.cancel) {
                        viewModel.send(.cancel)
                    }
                    .buttonStyle(.toolbarPill(.red))
                } else {
                    Button(L10n.save) {
                        if access {
                            tempPolicy.allowedTags = tempPolicy.allowedTags
                                .appendedOrInit(tempTag)
                        } else {
                            tempPolicy.blockedTags = tempPolicy.blockedTags
                                .appendedOrInit(tempTag)
                        }

                        viewModel.send(.updatePolicy(tempPolicy))
                    }
                    .buttonStyle(.toolbarPill)
                    .disabled(!isValid)
                }
            }
            .onChange(of: tempTag) { newTag in
                tagViewModel.search(newTag)
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case .error:
                    UIDevice.feedback(.error)
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismiss()
                }
            }
        // TODO: Add when moved to @Stateful
        // .errorMessage($viewModel.error)
    }

    // MARK: - Content View

    private var contentView: some View {
        Form {
            Section(L10n.access) {
                Picker(L10n.access, selection: $access) {
                    Text(L10n.allowed).tag(true)
                    Text(L10n.blocked).tag(false)
                }
            } learnMore: {
                LabeledContent(
                    L10n.allowed,
                    value: L10n.accessTagAllowDescription
                )

                LabeledContent(
                    L10n.blocked,
                    value: L10n.accessTagBlockDescription
                )
            }

            ItemElementSearchView(
                name: $tempTag,
                population: tagViewModel.matches,
                isSearching: tagViewModel.background.states.contains(.searching),
                alreadyOnItem: alreadyOnItem,
                existsOnServer: existsOnServer
            )
        }
    }
}
