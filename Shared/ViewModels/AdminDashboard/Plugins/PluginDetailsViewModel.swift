//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
@Stateful
final class PluginDetailsViewModel: ViewModel, @preconcurrency Identifiable {

    @CasePathable
    enum Action {
        case refresh
        case getPlugin
        case getConfigurationPage
        case getManifest
        case setEnabled(isEnabled: Bool)
        case install
        case uninstall

        var transition: Transition {
            switch self {
            case .refresh, .getPlugin, .getConfigurationPage, .getManifest:
                .background(.refreshing)
            case .setEnabled, .install, .uninstall:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case refreshing
        case updating
    }

    enum State {
        case error
        case initial
    }

    @Published
    var plugin: PluginInfo
    @Published
    var package: PackageInfo?

    @Published
    private(set) var configurationPage: ConfigurationPageInfo?
    @Published
    private(set) var manifest: VersionInfo?

    var id: String? {
        plugin.id?.uppercased()
    }

    var versions: [VersionInfo] {
        if let versions = package?.versions, versions.isNotEmpty {
            return versions
        }

        return manifest.map { [$0] } ?? []
    }

    init(plugin: PluginInfo, package: PackageInfo?) {
        self.plugin = plugin
        self.package = package
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        try await _getPlugin()
        try await _getConfigurationPage()
        try await _getManifest()
    }

    @Function(\Action.Cases.getPlugin)
    private func _getPlugin() async throws {
        guard let id = plugin.id else { return }

        let request = Paths.getPlugins
        let response = try await send(request)

        let plugins = response.value.filter { $0.id?.caseInsensitiveCompare(id) == .orderedSame }

        if let current = plugins.first(where: \.isInstalled) ?? plugins.first {
            plugin = current
        } else if let package {
            plugin = PluginInfo(package: package)
        }
    }

    @Function(\Action.Cases.getConfigurationPage)
    private func _getConfigurationPage() async throws {
        guard let id = plugin.id else { return }

        let request = Paths.getConfigurationPages()
        let response = try await send(request)

        let pages = response.value.filter { $0.pluginID?.caseInsensitiveCompare(id) == .orderedSame }

        configurationPage = pages.first { $0.enableInMainMenu == true } ?? pages.first
    }

    @Function(\Action.Cases.getManifest)
    private func _getManifest() async throws {
        guard plugin.isInstalled, let id = plugin.id else { return }

        let request = Paths.getPluginManifest(pluginID: id).withResponse(VersionInfo.self)
        let response = try await send(request)

        manifest = response.value
    }

    @Function(\Action.Cases.setEnabled)
    private func _setEnabled(_ isEnabled: Bool) async throws {
        guard let id = plugin.id, let version = plugin.version else {
            logger.error("Plugin ID or version is missing")
            throw ErrorMessage(L10n.unknownError)
        }

        let request = isEnabled
            ? Paths.enablePlugin(pluginID: id, version: version)
            : Paths.disablePlugin(pluginID: id, version: version)
        try await send(request)

        // Don't assume the result as disabling a plugin can vary in outcome
        try await _getPlugin()
    }

    @Function(\Action.Cases.install)
    private func _install() async throws {
        guard let name = plugin.name else {
            logger.error("Plugin name is missing")
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.installPackage(
            name: name,
            parameters: .init(assemblyGuid: plugin.id)
        )
        try await send(request)

        try await _getPlugin()
    }

    @Function(\Action.Cases.uninstall)
    private func _uninstall() async throws {
        guard let id = plugin.id, let version = plugin.version else {
            logger.error("Plugin ID or version is missing")
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.uninstallPluginByVersion(pluginID: id, version: version)
        try await send(request)

        try await _getPlugin()
    }
}
