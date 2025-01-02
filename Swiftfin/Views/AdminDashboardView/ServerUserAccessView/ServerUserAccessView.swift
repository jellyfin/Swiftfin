//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserMediaAccessView: View {

    // MARK: - Observed & Environment Objects

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    // MARK: - Policy Variable

    @State
    private var tempPolicy: UserPolicy

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
        self.tempPolicy = viewModel.user.policy ?? UserPolicy()
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.mediaAccess)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
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
            .onFirstAppear {
                viewModel.send(.loadLibraries())
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

    @ViewBuilder
    var contentView: some View {
        List {
            accessView
            deletionView
        }
    }

    // MARK: - Media Access View

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

    // MARK: - Media Deletion View

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
                    viewModel.libraries.filter { $0.collectionType != "boxsets" },
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
