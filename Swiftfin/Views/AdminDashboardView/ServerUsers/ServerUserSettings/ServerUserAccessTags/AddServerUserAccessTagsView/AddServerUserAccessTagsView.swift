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

    private var isValid: Bool {
        tempTag.isNotEmpty && !tagIsDuplicate
    }

    private var tagIsDuplicate: Bool {
        viewModel.user.policy!.blockedTags!.contains(tempTag) || viewModel.user.policy!.allowedTags!.contains(tempTag)
    }

    private var tagAlreadyExists: Bool {
        tagViewModel.matches.contains {
            $0.localizedCaseInsensitiveCompare(tempTag) == .orderedSame
        }
    }

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
        self.tempPolicy = viewModel.user.policy!
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
                if viewModel.backgroundStates.contains(.refreshing) {
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
            .onChange(of: tempTag) { _ in
                tagViewModel.search(tempTag)
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
    }

    // MARK: - Content View

    private var contentView: some View {
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
                isSearching: tagViewModel.background.states.contains(.searching)
            )
        }
    }
}
