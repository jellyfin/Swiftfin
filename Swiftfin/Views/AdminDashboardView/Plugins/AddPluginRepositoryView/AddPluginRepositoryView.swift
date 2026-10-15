//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AddPluginRepositoryView: View {

    @ObservedObject
    var viewModel: PluginRepositoriesViewModel

    @Router
    private var router

    @State
    private var name: String = ""
    @State
    private var url: String = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedURL: String {
        url.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDuplicateName: Bool {
        viewModel.repositories.contains {
            $0.name?.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(trimmedName) == .orderedSame
        }
    }

    private var isDuplicateURL: Bool {
        let normalizedURL: (String) -> String = {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingSuffix("/").lowercased()
        }

        return viewModel.repositories.contains {
            $0.url.map(normalizedURL) == normalizedURL(trimmedURL)
        }
    }

    private var isValidURL: Bool {
        guard let components = URLComponents(string: trimmedURL) else { return false }

        return ["http", "https"].contains(components.scheme?.lowercased()) && components.host?.isNotEmpty == true
    }

    var body: some View {
        Form {
            Section {
                TextField(L10n.name, text: $name)
                    .autocorrectionDisabled()
            } header: {
                Text(L10n.name)
            } footer: {
                if trimmedName.isEmpty {
                    Label(L10n.nameRequired, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else if isDuplicateName {
                    Label(L10n.repositoryNameAlreadyExists, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Section {
                TextField(L10n.url, text: $url)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text(L10n.url)
            } footer: {
                if trimmedURL.isEmpty {
                    Label(L10n.urlRequired, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else if !isValidURL {
                    Label(L10n.invalidURL, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else if isDuplicateURL {
                    Label(L10n.repositoryURLAlreadyExists, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }
        }
        .navigationTitle(L10n.addRepository.localizedCapitalized)
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            let saveAction: () -> Void = {
                UIDevice.impact(.light)
                viewModel.add(
                    RepositoryInfo(
                        isEnabled: true,
                        name: trimmedName,
                        url: trimmedURL
                    )
                )
                router.dismiss()
            }

            Group {
                if #available(iOS 26, *) {
                    Button(L10n.save, role: .confirm, action: saveAction)
                } else {
                    Button(L10n.save, action: saveAction)
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                }
            }
            .enabled(trimmedName.isNotEmpty && !isDuplicateName && isValidURL && !isDuplicateURL)
        }
    }
}
