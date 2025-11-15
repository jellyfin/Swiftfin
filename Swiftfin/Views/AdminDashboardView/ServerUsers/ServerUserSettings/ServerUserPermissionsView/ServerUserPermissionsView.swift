//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserPermissionsView: View {

    // MARK: - Observed & Environment Objects

    @Router
    private var router

    @ObservedObject
    var viewModel: ServerUserAdminViewModel

    // MARK: - Policy Variable

    @State
    private var tempPolicy: UserPolicy

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)

        guard let policy = viewModel.user.policy else {
            preconditionFailure("User policy cannot be empty.")
        }

        self.tempPolicy = policy
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.permissions)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
            }
            .topBarTrailing {
                if viewModel.backgroundStates.contains(.updating) {
                    ProgressView()
                }
                Button(L10n.save) {
                    if tempPolicy != viewModel.user.policy {
                        viewModel.send(.updatePolicy(tempPolicy))
                    }
                }
                .buttonStyle(.toolbarPill)
                .disabled(viewModel.user.policy == tempPolicy)
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismiss()
                }
            }
            .errorMessage($error)
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        switch viewModel.state {
        case let .error(error):
            ErrorView(error: error)
        case .initial:
            ErrorView(error: ErrorMessage(L10n.loadingUserFailed))
        default:
            permissionsListView
        }
    }

    // MARK: - Permissions List View

    @ViewBuilder
    var permissionsListView: some View {
        List {
            StatusSection(policy: $tempPolicy)

            ManagementSection(policy: $tempPolicy)

            MediaPlaybackSection(policy: $tempPolicy)

            ExternalAccessSection(policy: $tempPolicy)

            SyncPlaySection(policy: $tempPolicy)

            RemoteControlSection(policy: $tempPolicy)

            PermissionSection(policy: $tempPolicy)

            SessionsSection(policy: $tempPolicy)
        }
    }
}
