//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserLiveTVAccessView: View {

    @CurrentDate
    private var currentDate: Date

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    @Router
    private var router

    @State
    private var tempPolicy: UserPolicy

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel

        guard let policy = viewModel.user.policy else {
            preconditionFailure("User policy cannot be empty.")
        }

        self.tempPolicy = policy
    }

    var body: some View {
        List {
            Section(L10n.access) {
                Toggle(
                    L10n.liveTVAccess,
                    isOn: $tempPolicy.enableLiveTvAccess.coalesce(false)
                )
                Toggle(
                    L10n.liveTVRecordingManagement,
                    isOn: $tempPolicy.enableLiveTvManagement.coalesce(false)
                )
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.liveTVAccessCapitalized)
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
            let saveAction: () -> Void = {
                if tempPolicy != viewModel.user.policy {
                    viewModel.updatePolicy(tempPolicy)
                }
            }

            Group {
                if #available(iOS 26, *), Defaults[.isLiquidGlassEnabled] {
                    Button(L10n.save, role: .confirm, action: saveAction)
                } else {
                    Button(L10n.save, action: saveAction)
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                }
            }
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
}
