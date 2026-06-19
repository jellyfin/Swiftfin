//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: Should be using the expected ItemComponentEditor's element view

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

    private let supportsPeopleFields: Bool
    private let population: [Element]
    private let isSearching: Bool
    private let alreadyOnItem: Bool
    private let existsOnServer: Bool
    private let idForElement: (Element) -> String?
    private let nameForElement: (Element) -> String

    @ViewBuilder
    private func row(_ match: Element) -> some View {
        switch match {
        case let person as BaseItemPerson:
            BaseItemPersonLibraryListElement(
                person: person,
                libraryStyle: .init(displayType: .list, posterDisplayType: .portrait, listColumnCount: 1)
            ) {
                select(match)
            }
            .disabled(name == nameForElement(match))
        default:
            Button {
                select(match)
            } label: {
                Text(nameForElement(match))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.primary)
            .disabled(name == nameForElement(match))
        }
    }

    private func select(_ match: Element) {
        name = nameForElement(match)
        id = idForElement(match)
    }

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
            .animation(.linear, value: name)
        }
        .onFirstAppear {
            isNameFocused = true
        }

        if supportsPeopleFields {
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
                        row(result)
                    }
                } else if !isSearching {
                    Text(L10n.none)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } header: {
                HStack(spacing: 4) {
                    Text(L10n.existingItems)

                    Text(String.hyphen)

                    Text(population.count.description)

                    if isSearching {
                        ProgressView()
                    }
                }
                .animation(.linear, value: isSearching)
            }
        }
    }
}

extension ItemElementSearchView {

    // MARK: - Initializer for Generic `ItemElement`

    init(
        name: Binding<String>,
        id: Binding<String?>,
        supportsPeopleFields: Bool,
        personKind: Binding<PersonKind>,
        personRole: Binding<String>,
        population: [Element],
        isSearching: Bool,
        alreadyOnItem: Bool,
        existsOnServer: Bool,
        idForElement: @escaping (Element) -> String?,
        nameForElement: @escaping (Element) -> String
    ) {
        self._name = name
        self._id = id
        self._personKind = personKind
        self._personRole = personRole
        self.supportsPeopleFields = supportsPeopleFields
        self.population = population
        self.isSearching = isSearching
        self.alreadyOnItem = alreadyOnItem
        self.existsOnServer = existsOnServer
        self.idForElement = idForElement
        self.nameForElement = nameForElement
    }

    // MARK: - Initializer for Tags

    init(
        name: Binding<String>,
        population: [Element],
        isSearching: Bool,
        alreadyOnItem: Bool,
        existsOnServer: Bool,
        idForElement: @escaping (Element) -> String? = { _ in nil },
        nameForElement: @escaping (Element) -> String
    ) {
        self._name = name
        self._id = .constant(nil)
        self._personKind = .constant(.unknown)
        self._personRole = .constant("")
        self.supportsPeopleFields = false
        self.population = population
        self.isSearching = isSearching
        self.alreadyOnItem = alreadyOnItem
        self.existsOnServer = existsOnServer
        self.idForElement = idForElement
        self.nameForElement = nameForElement
    }
}
