//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AddServerUserAccessTagsView: View {

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    // MARK: - Access Tag Variables

    @State
    private var tempPolicy: UserPolicy
    @State
    private var tempTag: String = ""
    @State
    private var access: Bool = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
        self.tempPolicy = viewModel.user.policy!
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle("Add Access Tag")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
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
                        saveTag()
                    }
                    .buttonStyle(.toolbarPill)
                    .disabled(tempTag.isEmpty)
                }
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                }
            }
            .errorMessage($error)
    }

    // MARK: - Content View

    private var contentView: some View {
        Form {
            Section(L10n.access) {
                Toggle(L10n.access, isOn: $access)
                    .disabled(true)

                TextField(L10n.tags, text: $tempTag)
            }
        }
    }

    // MARK: - Save Schedule

    private func saveTag() {
        if access {
            /* tempPolicy.blockedTags = tempPolicy.allowedTags
             .appendedOrInit(tempTag) */
        } else {
            tempPolicy.blockedTags = tempPolicy.blockedTags
                .appendedOrInit(tempTag)
        }

        viewModel.send(.updatePolicy(tempPolicy))
    }
}
