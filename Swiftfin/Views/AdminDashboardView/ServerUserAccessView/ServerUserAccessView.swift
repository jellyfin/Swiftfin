//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserAccessView: View {

    // MARK: - Environment

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    // MARK: - ViewModel

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel

    // MARK: - State Variables

    @State
    private var tempPolicy: UserPolicy
    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

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
            .onFirstAppear {
                viewModel.send(.loadLibraries(isHidden: false))
            }
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
                ForEach(viewModel.libraries, id: \.id) { library in
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
