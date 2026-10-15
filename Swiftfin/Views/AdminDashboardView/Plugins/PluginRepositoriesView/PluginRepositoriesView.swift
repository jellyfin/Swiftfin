//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PluginRepositoriesView: View {

    @ObservedObject
    var viewModel: PluginRepositoriesViewModel

    @Router
    private var router

    var body: some View {
        List {
            ListTitleSection(
                L10n.repositories,
                description: L10n.repositoriesDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsPluginRepositories)
            }

            if viewModel.repositories.isNotEmpty {
                ForEach(viewModel.repositories, id: \.self) { repository in
                    StateAdapter(initialValue: false) { isPresentingConfirmation in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(repository.name ?? L10n.unknown)
                                .fontWeight(.semibold)
                                .lineLimit(2)

                            Text(repository.url ?? L10n.unknown)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .swipeActions {
                            Button(L10n.delete, systemImage: "trash") {
                                isPresentingConfirmation.wrappedValue = true
                            }
                            .tint(.red)
                        }
                        .confirmationDialog(
                            L10n.delete,
                            isPresented: isPresentingConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button(L10n.delete, role: .destructive) {
                                viewModel.remove(repository)
                            }

                            Button(L10n.cancel, role: .cancel) {}
                        } message: {
                            Text(L10n.deleteItemConfirmation)
                        }
                    }
                }
            } else {
                Button(L10n.add) {
                    router.route(to: .addPluginRepository(viewModel: viewModel))
                }
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.repositories)
        .navigationTitle(L10n.repositories)
        .toolbarTitleDisplayMode(.inline)
        .topBarTrailing {

            if viewModel.background.is(.updating) {
                ProgressView()
            }

            if viewModel.repositories.isNotEmpty {
                Button(L10n.add) {
                    router.route(to: .addPluginRepository(viewModel: viewModel))
                    UIDevice.impact(.light)
                }
                .backport
                .buttonStyle(.glassProminent)
                .controlSize(.small)
            }
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .errorMessage($viewModel.error)
    }
}
