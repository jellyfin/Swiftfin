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

    @State
    private var error: Error?

    private var isValid: Bool {
        tempTag.isNotEmpty && !tagIsDuplicate
    }

    private var tagIsDuplicate: Bool {
        viewModel.user.policy!.blockedTags!.contains(tempTag) || viewModel.user.policy!.allowedTags!.contains(tempTag)
    }

    private var tagAlreadyExists: Bool {
        tagViewModel.trie.contains(key: tempTag.localizedLowercase)
    }

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
        self.tempPolicy = viewModel.user.policy!
        self._tagViewModel = StateObject(wrappedValue: TagEditorViewModel(item: .init()))
    }

    var body: some View {
        Form {
            TagInput(
                access: $access,
                tag: $tempTag,
                tagIsDuplicate: tagIsDuplicate,
                tagAlreadyExists: tagAlreadyExists
            )

            SearchResultsSection(
                tag: $tempTag,
                tags: tagViewModel.matches,
                isSearching: tagViewModel.backgroundStates.contains(.searching)
            )
        }
        .navigationTitle(L10n.addAccessTag.localizedCapitalized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .refreshable {
            viewModel.refresh()
        }
        .topBarTrailing {
            if viewModel.background.is(.refreshing) {
                ProgressView()
            }
            if viewModel.background.is(.updating) {
                Button(L10n.cancel) {
                    viewModel.cancel()
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

                    viewModel.updatePolicy(tempPolicy)
                }
                .buttonStyle(.toolbarPill)
                .disabled(!isValid)
            }
        }
        .onFirstAppear {
            tagViewModel.send(.load)
        }
        .onChange(of: tempTag) { _ in
            if !tagViewModel.backgroundStates.contains(.loading) {
                tagViewModel.send(.search(tempTag))
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .onReceive(tagViewModel.events) { event in
            switch event {
            case .updated:
                break
            case .loaded:
                tagViewModel.send(.search(tempTag))
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
            }
        }
        .errorMessage($error)
        .errorMessage($viewModel.error)
    }
}
