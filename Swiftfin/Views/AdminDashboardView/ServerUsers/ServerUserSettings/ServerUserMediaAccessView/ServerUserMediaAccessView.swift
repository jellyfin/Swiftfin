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

struct ServerUserMediaAccessView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

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
        contentView
            .navigationTitle(L10n.mediaAccess.localizedCapitalized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
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
            .onFirstAppear {
                viewModel.getLibraries(isHidden: false)
            }
            .refreshable {
                viewModel.getLibraries(isHidden: false)
                viewModel.refresh()
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
    var contentView: some View {
        List {
            accessView
            deletionView
        }
    }

    @ViewBuilder
    var accessView: some View {
        Section(L10n.access) {
            Toggle(
                L10n.enableAllLibraries,
                isOn: $tempPolicy.enableAllFolders.coalesce(false)
            )
        }

        if tempPolicy.enableAllFolders == false {
            Section {
                ForEach(viewModel.libraries, id: \.id) { library in
                    Toggle(
                        library.displayTitle,
                        isOn: $tempPolicy.enabledFolders
                            .coalesce([])
                            .contains(library.id!)
                    )
                }
            }
        }
    }

    @ViewBuilder
    var deletionView: some View {
        Section(L10n.deletion) {
            Toggle(
                L10n.enableAllLibraries,
                isOn: $tempPolicy.enableContentDeletion.coalesce(false)
            )
        }

        if tempPolicy.enableContentDeletion == false {
            Section {
                ForEach(
                    viewModel.libraries.filter { $0.collectionType != .boxsets },
                    id: \.id
                ) { library in
                    Toggle(
                        library.displayTitle,
                        isOn: $tempPolicy.enableContentDeletionFromFolders
                            .coalesce([])
                            .contains(library.id!)
                    )
                }
            }
        }
    }
}
