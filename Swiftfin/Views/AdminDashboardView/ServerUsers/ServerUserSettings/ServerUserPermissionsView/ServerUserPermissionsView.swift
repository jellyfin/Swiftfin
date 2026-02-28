//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserPermissionsView: View {

    @Router
    private var router

    @ObservedObject
    var viewModel: ServerUserAdminViewModel

    @State
    private var tempPolicy: UserPolicy

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)

        guard let policy = viewModel.user.policy else {
            preconditionFailure("User policy cannot be empty.")
        }

        self.tempPolicy = policy
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                ProgressView()
            case .content:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .navigationTitle(L10n.permissions)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .refreshable {
            viewModel.refresh()
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            }
            Button(L10n.save) {
                if tempPolicy != viewModel.user.policy {
                    viewModel.updatePolicy(tempPolicy)
                }
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.user.policy == tempPolicy)
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

    @ViewBuilder
    private var contentView: some View {
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
