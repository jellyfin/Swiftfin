//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemElementSearchView<Editor: ItemComponentEditor>: View {

    @FocusState
    private var isNameFocused: Bool

    @Binding
    private var input: ItemComponentEditorInput

    private let editor: Editor
    private let population: [Editor.Element]
    private let isSearching: Bool
    private let alreadyOnItem: Bool
    private let existsOnServer: Bool

    private var listLibraryStyle: LibraryStyle {
        .init(
            displayType: .list,
            posterDisplayType: Editor.Element.supportedLibraryStyleOptions.fallbackPosterDisplayType,
            listColumnCount: 1
        )
    }

    private func select(_ match: Editor.Element) {
        input.name = editor.name(for: match)
        input.id = editor.id(for: match)
    }

    init(
        input: Binding<ItemComponentEditorInput>,
        editor: Editor,
        population: [Editor.Element],
        isSearching: Bool,
        alreadyOnItem: Bool,
        existsOnServer: Bool
    ) {
        self._input = input
        self.editor = editor
        self.population = population
        self.isSearching = isSearching
        self.alreadyOnItem = alreadyOnItem
        self.existsOnServer = existsOnServer
    }

    var body: some View {
        Section {
            TextField(L10n.name, text: $input.name)
                .autocorrectionDisabled()
                .focused($isNameFocused)
        } header: {
            Text(L10n.name)
        } footer: {
            Group {
                if input.name.isEmpty {
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
            .animation(.linear, value: input.name)
        }
        .onFirstAppear {
            isNameFocused = true
        }

        if Editor.self == PeopleComponentEditor.self {
            Section {
                Picker(L10n.type, selection: $input.personKind) {
                    ForEach(PersonKind.allCases, id: \.self) { kind in
                        Text(kind.displayTitle).tag(kind)
                    }
                }
                if input.personKind == .actor {
                    TextField(L10n.role, text: $input.personRole)
                        .autocorrectionDisabled()
                }
            }
        }

        if input.name.isNotEmpty {
            Section {
                if population.isNotEmpty {
                    ForEach(population, id: \.self) { result in
                        result.makeBody(libraryStyle: listLibraryStyle) {
                            select(result)
                        }
                        .disabled(input.name == editor.name(for: result))
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
