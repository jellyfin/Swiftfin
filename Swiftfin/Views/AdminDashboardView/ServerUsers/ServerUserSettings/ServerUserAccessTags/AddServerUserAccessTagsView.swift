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

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    @Router
    private var router

    @State
    private var access: Bool = false
    @State
    private var tempPolicy: UserPolicy
    @State
    private var input: ItemComponentEditorInput = .init(
        id: nil,
        name: "",
        personKind: .unknown,
        personRole: ""
    )

    @StateObject
    private var tagViewModel: ItemComponentEditorViewModel<TagComponentEditor>

    private var alreadyOnItem: Bool {
        let blocked = tempPolicy.blockedTags ?? []
        let allowed = tempPolicy.allowedTags ?? []
        return blocked.contains { $0.caseInsensitiveCompare(input.name) == .orderedSame }
            || allowed.contains { $0.caseInsensitiveCompare(input.name) == .orderedSame }
    }

    private var existsOnServer: Bool {
        input.name.isNotEmpty && tagViewModel.editor.matchExists(named: input.name, in: tagViewModel.matches)
    }

    private var isValid: Bool {
        input.name.isNotEmpty && !alreadyOnItem
    }

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
        self.tempPolicy = viewModel.user.policy ?? UserPolicy(
            authenticationProviderID: "",
            passwordResetProviderID: ""
        )
        self._tagViewModel = StateObject(wrappedValue: ItemComponentEditorViewModel(
            editor: TagComponentEditor(),
            item: .init()
        ))
    }

    // MARK: - Body

    var body: some View {
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
                input: $input,
                editor: tagViewModel.editor,
                population: tagViewModel.matches,
                isSearching: tagViewModel.background.states.contains(.searching),
                alreadyOnItem: alreadyOnItem,
                existsOnServer: existsOnServer
            )
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.addAccessTag.localizedCapitalized)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.is(.refreshing) ||
                viewModel.background.is(.updating) ||
                tagViewModel.background.states.contains(.searching)
            {
                ProgressView()
            }

            if viewModel.background.states.contains(.updating) {
                Button(L10n.cancel) {
                    viewModel.cancel()
                }
                .buttonStyle(.toolbarPill(.red))
            } else {
                Button(L10n.save) {
                    if access {
                        tempPolicy.allowedTags = tempPolicy.allowedTags
                            .appendedOrInit(input.name)
                    } else {
                        tempPolicy.blockedTags = tempPolicy.blockedTags
                            .appendedOrInit(input.name)
                    }

                    viewModel.updatePolicy(tempPolicy)
                }
                .buttonStyle(.toolbarPill)
                .disabled(!isValid)
            }
        }
        .onChange(of: input.name) { newTag in
            tagViewModel.search(newTag)
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
