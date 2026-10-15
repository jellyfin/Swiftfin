//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

struct PluginDetailsView: View {

    @Router
    private var router

    @ObservedObject
    var viewModel: PluginDetailsViewModel

    var body: some View {
        List {
            ListTitleSection(
                viewModel.plugin.displayTitle,
                description: viewModel.package?.description ?? viewModel.plugin.description
            )

            if viewModel.plugin.isInstalled {
                Section {
                    Toggle(
                        L10n.enabled,
                        isOn: Binding(
                            get: { viewModel.plugin.status != .disabled },
                            set: { viewModel.setEnabled(isEnabled: $0) }
                        )
                    )
                    .disabled(
                        viewModel.background.is(.updating) ||
                            ![.active, .disabled, .restart].contains(viewModel.plugin.status)
                    )

                    if let configurationPage = viewModel.configurationPage {
                        ChevronButton(L10n.configuration, external: true) {
                            router.route(to: .jellyfinWebPage(
                                "configurationpage",
                                queryItems: [.init(name: "name", value: configurationPage.name)]
                            ))
                        }
                    }
                }
            }

            Section(L10n.details) {
                if let owner = viewModel.package?.owner {
                    LabeledContent(L10n.author, value: owner)
                }

                if let category = viewModel.package?.pluginCategory {
                    LabeledContent(L10n.category, value: category.displayTitle)
                }

                if let version = viewModel.plugin.version ?? viewModel.package?.versions?.first?.version {
                    LabeledContent(L10n.version, value: version)
                        .monospacedDigit()
                }

                if let status = viewModel.plugin.status {
                    LabeledContent(L10n.status, value: status.displayTitle)
                }
            }

            if viewModel.versions.isNotEmpty {
                Section(L10n.history) {
                    ForEach(viewModel.versions, id: \.self) { version in
                        DisclosureGroup {
                            Group {
                                if let changelog = version.changelog?.nilIfBlank {
                                    Text(changelog.markdown)
                                } else {
                                    Text(L10n.none)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(version.version ?? L10n.unknown)
                                    .fontWeight(.semibold)

                                Group {
                                    if let timestamp = version.timestamp, let date = try? Date(timestamp, strategy: .iso8601) {
                                        LabeledContent(L10n.release, value: date, format: .dateTime.year().month().day())
                                    }

                                    if let targetAbi = version.targetAbi {
                                        LabeledContent(L10n.jellyfin, value: targetAbi)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            .monospacedDigit()
                        }
                    }
                }
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.package)
        .navigationTitle(viewModel.plugin.displayTitle)
        .toolbarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.refresh()
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            }

            if viewModel.plugin.isInstalled {
                if viewModel.plugin.canUninstall == true {
                    StateAdapter(initialValue: false) { isPresentingConfirmation in
                        Button(L10n.uninstall, role: .destructive) {
                            isPresentingConfirmation.wrappedValue = true
                        }
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                        .disabled(viewModel.background.is(.updating))
                        .confirmationDialog(
                            L10n.uninstall,
                            isPresented: isPresentingConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button(L10n.uninstall, role: .destructive) {
                                viewModel.uninstall()
                            }

                            Button(L10n.cancel, role: .cancel) {}
                        } message: {
                            Text(L10n.uninstallPluginWarning)
                        }
                    }
                }
            } else {
                Button(L10n.install) {
                    viewModel.install()
                }
                .backport
                .buttonStyle(.glassProminent)
                .controlSize(.small)
                .disabled(viewModel.background.is(.updating))
            }
        }
        .errorMessage($viewModel.error)
    }
}
