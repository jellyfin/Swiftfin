//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

@MainActor
@Stateful
final class PluginsViewModel: ViewModel {

    struct Environment: Hashable, WithDefaultValue {

        var category: PluginCategory?
        var isInstalled: Bool?

        static var `default`: Self {
            .init(
                category: nil,
                isInstalled: true
            )
        }
    }

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.initial, then: .content)
                    .whenBackground(.refreshing)
            }
        }
    }

    enum BackgroundState {
        case refreshing
    }

    enum State {
        case content
        case error
        case initial
    }

    @Published
    var environment: Environment = .default
    @Published
    private(set) var packages: [PackageInfo] = []
    @Published
    private(set) var plugins: OrderedDictionary<String, PluginDetailsViewModel> = [:]

    private var pluginCancellables = Set<AnyCancellable>()

    let repositoriesViewModel = PluginRepositoriesViewModel()

    var filteredPlugins: [PluginDetailsViewModel] {
        plugins.values.filter { viewModel in
            (environment.isInstalled == nil || viewModel.plugin.isInstalled == environment.isInstalled) &&
                (environment.category == nil || viewModel.package?.pluginCategory == environment.category)
        }
    }

    var categories: [PluginCategory] {
        let categories = Set(packages.compactMap(\.pluginCategory))
        return PluginCategory.allCases.filter(categories.contains)
    }

    override init() {
        super.init()

        repositoriesViewModel.events
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        try await getPackages()
        try await getPlugins()
    }

    private func getPackages() async throws {
        let request = Paths.getPackages
        let response = try await send(request)

        packages = response.value
    }

    private func getPlugins() async throws {
        let request = Paths.getPlugins
        let response = try await send(request)

        let installed = response.value.filter(\.isInstalled)
        let installedIDs = Set(installed.compactMap(\.normalizedID))

        let available = packages
            .filter { !installedIDs.contains($0.id ?? "") }
            .map(PluginInfo.init(package:))

        updatePlugins(installed + available)
    }

    private func updatePlugins(_ incomingPlugins: [PluginInfo]) {
        var updatedPlugins: OrderedDictionary<String, PluginDetailsViewModel> = [:]
        pluginCancellables.removeAll()

        for plugin in incomingPlugins.sorted(using: \.displayTitle) {
            guard let id = plugin.normalizedID, updatedPlugins[id] == nil else { continue }

            let package = packages.first { $0.id == id }
            let viewModel = plugins[id] ?? PluginDetailsViewModel(plugin: plugin, package: package)

            viewModel.plugin = plugin
            viewModel.package = package

            viewModel.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &pluginCancellables)

            updatedPlugins[id] = viewModel
        }

        plugins = updatedPlugins
    }
}
