//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

struct ContentGroupEditorView: View {

    @StateObject
    private var group: PublishedBox<ContentGroupConfiguration>
    @State
    private var isNextUpDaysPresented = false

    @Router
    private var router

    init(group: Binding<ContentGroupConfiguration>) {
        _group = StateObject(wrappedValue: PublishedBox(source: group))
    }

    private var libraryConfiguration: Binding<LibraryGroupConfiguration>? {
        guard case .library = group.value.source else { return nil }

        return Binding {
            guard case let .library(configuration) = group.value.source else { return .init() }

            return configuration
        } set: {
            group.value.source = .library($0)
        }
    }

    private var resumeConfiguration: Binding<ResumeGroupConfiguration>? {
        guard case .resume = group.value.source else { return nil }

        return Binding {
            guard case let .resume(configuration) = group.value.source else { return .init() }

            return configuration
        } set: {
            group.value.source = .resume($0)
        }
    }

    private var nextUpConfiguration: Binding<NextUpGroupConfiguration>? {
        guard case .nextUp = group.value.source else { return nil }

        return Binding {
            guard case let .nextUp(configuration) = group.value.source else { return .init() }

            return configuration
        } set: {
            group.value.source = .nextUp($0)
        }
    }

    private var liveTVConfiguration: Binding<LiveTVGroupConfiguration>? {
        guard case .liveTV = group.value.source else { return nil }

        return Binding {
            guard case let .liveTV(configuration) = group.value.source else { return .init() }

            return configuration
        } set: {
            group.value.source = .liveTV($0)
        }
    }

    private var genresConfiguration: Binding<GenresGroupConfiguration>? {
        guard case .genres = group.value.source else { return nil }

        return Binding {
            guard case let .genres(configuration) = group.value.source else { return .init() }

            return configuration
        } set: {
            group.value.source = .genres($0)
        }
    }

    private func chooseLibrary(
        selectionID: String?,
        action: @escaping (ItemReference?) -> Void
    ) {
        router.route(
            to: NavigationRoute(id: "layout-group-library-\(group.value.id)") {
                LayoutLibraryPickerView(selectionID: selectionID) { item in
                    action(item.map(ItemReference.init(item:)))
                }
            }
        )
    }

    private func chooseSeries(
        selectionID: String?,
        action: @escaping (ItemReference?) -> Void
    ) {
        router.route(
            to: NavigationRoute(id: "layout-group-series-\(group.value.id)") {
                LayoutItemPickerView(
                    selectionID: selectionID,
                    includedItemTypes: [.series],
                    nilSelectionTitle: L10n.all,
                    title: L10n.series
                ) { item in
                    action(item.map(ItemReference.init(item:)))
                }
            }
        )
    }

    private func chooseItemTypes(
        _ selection: Binding<[BaseItemKind]>,
        sources: [BaseItemKind] = BaseItemKind.supportedCases
    ) {
        router.route(
            to: NavigationRoute(id: "layout-group-item-types-\(group.value.id)") {
                SelectorView(
                    selection: selection,
                    sources: sources,
                    type: .multi
                )
                .navigationTitle(L10n.type)
                .toolbarTitleDisplayMode(.inline)
            }
        )
    }

    private func nextUpDays(
        _ configuration: Binding<NextUpGroupConfiguration>
    ) -> Binding<Int> {
        Binding {
            configuration.wrappedValue.maxDays ?? 0
        } set: { newValue in
            let clampedValue = min(max(newValue, 0), 1000)
            configuration.wrappedValue.maxDays = clampedValue == 0 ? nil : clampedValue
        }
    }

    @ContentBuilder
    private func sourceRow(
        title: String,
        reference: ItemReference?,
        action: @escaping () -> Void
    ) -> some View {
        ChevronButton(title, action: action) {
            Text(reference?.displayTitle ?? L10n.all)
        }
    }

    @ContentBuilder
    private func posterSettings(_ settings: Binding<PosterGroupSettings>) -> some View {
        Section(L10n.style) {
            PosterGroupSettingsEditor(settings: settings)
        }
    }

    @ContentBuilder
    private var libraryEditor: some View {
        if let configuration = libraryConfiguration {
            Section(L10n.source) {
                sourceRow(
                    title: L10n.libraries,
                    reference: configuration.wrappedValue.library
                ) {
                    chooseLibrary(selectionID: configuration.wrappedValue.library?.id) {
                        configuration.wrappedValue.library = $0
                    }
                }
            }

            LayoutFilterEditor(filters: configuration.filters, library: configuration.wrappedValue.library)
            posterSettings(configuration.poster)
        }
    }

    @ContentBuilder
    private var resumeEditor: some View {
        if let configuration = resumeConfiguration {
            Section(L10n.source) {
                sourceRow(
                    title: L10n.libraries,
                    reference: configuration.wrappedValue.parent
                ) {
                    chooseLibrary(selectionID: configuration.wrappedValue.parent?.id) {
                        configuration.wrappedValue.parent = $0
                    }
                }

                SearchFilterRow(query: configuration.searchTerm)

                ChevronButton(L10n.type) {
                    chooseItemTypes(configuration.itemTypes, sources: ResumeItemsLibrary().libraryItemTypes)
                } content: {
                    Text(configuration.wrappedValue.itemTypes.isEmpty ? L10n.all : "\(configuration.wrappedValue.itemTypes.count)")
                }
            }

            posterSettings(configuration.poster)
        }
    }

    @ContentBuilder
    private var nextUpEditor: some View {
        if let configuration = nextUpConfiguration {
            Section(L10n.source) {
                sourceRow(
                    title: L10n.libraries,
                    reference: configuration.wrappedValue.library
                ) {
                    chooseLibrary(selectionID: configuration.wrappedValue.library?.id) {
                        configuration.wrappedValue.library = $0
                        configuration.wrappedValue.series = nil
                    }
                }

                ChevronButton(L10n.series) {
                    chooseSeries(selectionID: configuration.wrappedValue.series?.id) {
                        configuration.wrappedValue.series = $0
                        if $0 != nil {
                            configuration.wrappedValue.library = nil
                        }
                    }
                } content: {
                    Text(configuration.wrappedValue.series?.displayTitle ?? L10n.all)
                }

                Toggle(
                    L10n.nextUpRewatch,
                    isOn: configuration.enableRewatching
                )

                if configuration.wrappedValue.series == nil {
                    ChevronButton {
                        isNextUpDaysPresented = true
                    } label: {
                        LabeledContent {
                            if let maxDays = configuration.wrappedValue.maxDays {
                                Text(
                                    Duration.seconds(TimeInterval(maxDays) * 86400),
                                    format: .units(allowed: [.days], width: .abbreviated)
                                )
                            } else {
                                Text(L10n.unlimited)
                            }
                        } label: {
                            Text(L10n.nextUpDays)
                        }
                    }
                    .alert(
                        L10n.nextUpDays,
                        isPresented: $isNextUpDaysPresented
                    ) {
                        TextField(
                            L10n.days,
                            value: nextUpDays(configuration),
                            format: .number
                        )
                        .keyboardType(.numberPad)
                    } message: {
                        Text(L10n.nextUpDaysDescription)
                    }
                }
            }

            posterSettings(configuration.poster)
        }
    }

    @ContentBuilder
    private var liveTVEditor: some View {
        if let configuration = liveTVConfiguration {
            Section(L10n.liveTV) {
                Picker(L10n.liveTV, selection: configuration.element) {
                    ForEach(LiveTVElement.allCases, id: \.self) { element in
                        Label(element.displayTitle, systemImage: element.systemImage)
                            .tag(element)
                    }
                }
            }

            if configuration.wrappedValue.element != .quickLinks {
                posterSettings(configuration.poster)
            }
        }
    }

    @ContentBuilder
    private var genresEditor: some View {
        if let configuration = genresConfiguration {
            Section(L10n.source) {
                sourceRow(
                    title: L10n.libraries,
                    reference: configuration.wrappedValue.parent
                ) {
                    chooseLibrary(selectionID: configuration.wrappedValue.parent?.id) {
                        configuration.wrappedValue.parent = $0
                    }
                }

                SearchFilterRow(query: configuration.searchTerm)

                ChevronButton(L10n.type) {
                    chooseItemTypes(configuration.itemTypes)
                } content: {
                    Text(configuration.wrappedValue.itemTypes.isEmpty ? L10n.all : "\(configuration.wrappedValue.itemTypes.count)")
                }
            }
        }
    }

    @ContentBuilder
    private var configurationEditor: some View {
        switch group.value.source {
        case .library:
            libraryEditor
        case .resume:
            resumeEditor
        case .nextUp:
            nextUpEditor
        case .liveTV:
            liveTVEditor
        case .genres:
            genresEditor
        }
    }

    @ContentBuilder
    var body: some View {
        Form(systemImage: group.value.systemImage) {
            Section(L10n.name) {
                TextField(
                    L10n.name,
                    value: $group.value.title,
                    format: .nilIfEmptyString,
                    prompt: Text(group.value.source.displayTitle)
                )
            }

            configurationEditor
        }
        .navigationTitle(group.value.displayTitle)
        .toolbarTitleDisplayMode(.inline)
    }
}
