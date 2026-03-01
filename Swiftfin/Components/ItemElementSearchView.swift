//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemElementSearchView<Element: Hashable>: View {

    @FocusState
    private var isNameFocused: Bool

    @Binding
    private var name: String
    @Binding
    private var id: String?
    @Binding
    private var personKind: PersonKind
    @Binding
    private var personRole: String

    private let type: ItemArrayElements
    private let population: [Element]
    private let isSearching: Bool
    private let alreadyOnItem: Bool
    private let existsOnServer: Bool

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

                    if isSearching {
                        ProgressView()
                    }
                }
                .animation(.easeInOut, value: isSearching)
            }
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

extension ItemElementSearchView {

    // MARK: - Initializer for Generic `ItemElement`

    init(
        name: Binding<String>,
        id: Binding<String?>,
        type: ItemArrayElements,
        personKind: Binding<PersonKind>,
        personRole: Binding<String>,
        population: [Element],
        isSearching: Bool,
        alreadyOnItem: Bool,
        existsOnServer: Bool
    ) {
        self._name = name
        self._id = id
        self._personKind = personKind
        self._personRole = personRole
        self.type = type
        self.population = population
        self.isSearching = isSearching
        self.alreadyOnItem = alreadyOnItem
        self.existsOnServer = existsOnServer
    }

    // MARK: - Initializer for Tags

    init(
        name: Binding<String>,
        population: [Element],
        isSearching: Bool,
        alreadyOnItem: Bool,
        existsOnServer: Bool
    ) {
        self._name = name
        self._id = .constant(nil)
        self._personKind = .constant(.unknown)
        self._personRole = .constant("")
        self.type = .tags
        self.population = population
        self.isSearching = isSearching
        self.alreadyOnItem = alreadyOnItem
        self.existsOnServer = existsOnServer
    }
}
