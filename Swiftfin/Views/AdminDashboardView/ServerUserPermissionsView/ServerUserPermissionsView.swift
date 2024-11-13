//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserPermissionsView: View {

    // MARK: - Environment

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    // MARK: - ViewModel

    @ObservedObject
    var viewModel: ServerUserAdminViewModel

    // MARK: - State Variables

    @State
    private var tempPolicy: UserPolicy
    @State
    private var error: Error? = nil
    @State
    private var isPresentingError: Bool = false
    @State
    private var tempMaxSessionsPolicy: ActiveSessionsPolicy
    @State
    private var tempLoginFailurePolicy: LoginFailurePolicy
    @State
    private var tempMaxBitratePolicy: MaxBitratePolicy

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.tempPolicy = viewModel.user.policy ?? UserPolicy()
        self.tempMaxSessionsPolicy = ActiveSessionsPolicy.from(rawValue: viewModel.user.policy?.maxActiveSessions ?? 0)
        self.tempLoginFailurePolicy = LoginFailurePolicy.from(
            rawValue: viewModel.user.policy?.loginAttemptsBeforeLockout ?? 0,
            isAdministrator: viewModel.user.policy?.isAdministrator ?? false
        )
        self.tempMaxBitratePolicy = MaxBitratePolicy.from(rawValue: viewModel.user.policy?.remoteClientBitrateLimit ?? 0)
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.permissions)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
            }
            .topBarTrailing {
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
                    isPresentingError = true
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                }
            }
            .alert(
                L10n.error.text,
                isPresented: $isPresentingError,
                presenting: error
            ) { _ in
                Button(L10n.dismiss, role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        switch viewModel.state {
        case let .error(error):
            ErrorView(error: error)
        case .initial:
            ErrorView(error: JellyfinAPIError("Loading user failed"))
        default:
            permissionsListView
        }
    }

    // MARK: - Content View

    @ViewBuilder
    var permissionsListView: some View {
        List {
            StatusSection(policy: $tempPolicy)

            ManagementSection(policy: $tempPolicy)

            FeatureAccessSection(policy: $tempPolicy)

            MediaPlaybackSection(policy: $tempPolicy)

            ExternalAccessSection(
                maxBitratePolicy: $tempMaxBitratePolicy,
                policy: $tempPolicy
            )

            SyncPlaySection(policy: $tempPolicy)

            RemoteControlSection(policy: $tempPolicy)

            PermissionSection(policy: $tempPolicy)

            SessionsSection(
                policy: $tempPolicy,
                loginFailurePolicy: $tempLoginFailurePolicy,
                maxSessionsPolicy: $tempMaxSessionsPolicy
            )
        }
    }
}
