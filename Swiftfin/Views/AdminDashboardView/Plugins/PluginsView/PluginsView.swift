//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PluginsView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = PluginsViewModel()

    @ViewBuilder
    private var contentView: some View {
        List {
            ListTitleSection(
                L10n.plugins,
                description: L10n.pluginsDescription
            ) {
                UIApplication.shared.open(.jellyfinDocsPlugins)
            }

            if viewModel.filteredPlugins.isEmpty {
                Text(L10n.none)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.filteredPlugins) { pluginViewModel in
                    pluginViewModel.makeBody(libraryStyle: .default) {
                        router.route(to: .pluginDetails(viewModel: pluginViewModel))
                    }
                }
            }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                contentView

            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }

            case .initial:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .animation(.linear(duration: 0.1), value: viewModel.filteredPlugins.map(\.plugin))
        .animation(.linear(duration: 0.1), value: viewModel.environment)
        .navigationTitle(L10n.plugins)
        .toolbarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            viewModel.refresh()
        }
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.refreshing)
        ) {
            Section {
                Button(L10n.repositories, systemImage: "shippingbox") {
                    router.route(to: .pluginRepositories(viewModel: viewModel.repositoriesViewModel))
                }
            }

            Section(L10n.filters) {
                Picker(L10n.status, systemImage: "puzzlepiece.extension", selection: $viewModel.environment.isInstalled) {
                    Text(L10n.all)
                        .tag(Bool?.none)
                    Text(L10n.installed)
                        .tag(Bool?.some(true))
                    Text(L10n.available)
                        .tag(Bool?.some(false))
                }
                .pickerStyle(.menu)

                Picker(L10n.category, systemImage: "square.grid.2x2", selection: $viewModel.environment.category) {
                    Text(L10n.all)
                        .tag(PluginCategory?.none)

                    ForEach(viewModel.categories, id: \.self) { category in
                        Text(category.displayTitle)
                            .tag(PluginCategory?.some(category))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .errorMessage($viewModel.error)
    }
}
