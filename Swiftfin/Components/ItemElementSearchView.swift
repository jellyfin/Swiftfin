//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemElementSearchView<Element: Hashable>: View {

    @FocusState
    private var isNameFocused: Bool

    @Binding
    var name: String
    @Binding
    var id: String?
    @Binding
    var personKind: PersonKind
    @Binding
    var personRole: String

    let type: ItemArrayElements
    let population: [Element]
    let isSearching: Bool
    let alreadyOnItem: Bool
    let existsOnServer: Bool

    // MARK: - Body

    var body: some View {
        Section {
            TextField(L10n.name, text: $name)
                .autocorrectionDisabled()
                .focused($isNameFocused)
        } header: {
            Text(L10n.name)
        } footer: {
            Group {
                if name.isEmpty {
                    Label(L10n.required, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else if alreadyOnItem {
                    Label(L10n.itemAlreadyExists, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .red))
                } else if existsOnServer {
                    Label(L10n.existsOnServer, systemImage: "checkmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .green))
                } else {
                    Label(L10n.willBeCreatedOnServer, systemImage: "checkmark.seal.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .blue))
                }
            }
            .animation(.easeInOut, value: name)
            .animation(.easeInOut, value: alreadyOnItem)
            .animation(.easeInOut, value: existsOnServer)
        }
        .onFirstAppear {
            isNameFocused = true
        }

        if type == .people {
            Section {
                Picker(L10n.type, selection: $personKind) {
                    ForEach(PersonKind.allCases, id: \.self) { kind in
                        Text(kind.displayTitle).tag(kind)
                    }
                }
                if personKind == .actor {
                    TextField(L10n.role, text: $personRole)
                        .autocorrectionDisabled()
                }
            }
        }

        if name.isNotEmpty {
            Section {
                if population.isNotEmpty {
                    ForEach(population, id: \.self) { result in
                        Button {
                            name = type.getName(for: result)
                            id = type.getId(for: result)
                        } label: {
                            rowLabel(result)
                        }
                        .foregroundStyle(.primary)
                        .disabled(name == type.getName(for: result))
                    }
                } else if !isSearching {
                    Text(L10n.none)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } header: {
                HStack(spacing: 4) {
                    Text(L10n.existingItems)

                    Text("-")

                    Text(population.count.description)

                    ProgressView()
                }
                .animation(.easeInOut, value: isSearching)
            }
            .animation(.easeInOut, value: population.count)
        }
    }

    // MARK: - Row Label

    @ViewBuilder
    private func rowLabel(_ match: Element) -> some View {
        switch type {
        case .people:
            let person = match as! BaseItemPerson
            HStack {
                ZStack {
                    Color.clear
                    ImageView(person.portraitImageSources(maxWidth: 30, quality: 90))
                        .failure {
                            SystemImageContentView(systemName: "person.fill")
                        }
                }
                .posterStyle(.portrait)
                .frame(width: 30, height: 90)
                .padding(.horizontal)

                Text(type.getName(for: match))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        default:
            Text(type.getName(for: match))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
