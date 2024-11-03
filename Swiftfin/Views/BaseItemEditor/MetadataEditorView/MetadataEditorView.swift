//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct MetadataEditorView: View {

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @State
    private var tempItem: BaseItemDto

    @ObservedObject
    private var viewModel: ItemViewModel

    private let itemType: BaseItemKind

    init(item: BaseItemDto) {
        self.itemType = item.type!
        self.viewModel = ItemViewModel(item: item)
        _tempItem = State(initialValue: item)
    }

    var body: some View {
        Form {

            // MARK: - Sections that should exist for all items

            BaseItemSection(
                item: $tempItem,
                itemType: itemType
            )

            // MARK: - Sections for localization metadata

            LocalizationSection(item: $tempItem)

            if itemType == .series {
                seriesRuntimeSection
            }

            if itemType == .series || itemType == .person {
                endDateSection
            }

            if itemType == .movie || itemType == .trailer {
                criticRatingSection
            }

            if itemType == .series {
                seriesSpecificSection
            }

            if itemType == .audio {
                albumArtistSection
            }

            if itemType == .audio || itemType == .musicVideo {
                artistAndAlbumSection
            }

            if itemType == .boxSet {
                displayOrderSectionBoxSet
            } else if itemType == .series {
                displayOrderSectionSeries
            }

            LockMetadataSection(item: $tempItem)
        }
        .navigationBarTitle("Edit Item", displayMode: .inline)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Save") {
            saveIfNeeded()
        })
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }

    private var seriesRuntimeSection: some View {
        Section("Run Time") {
            TextField("Run Time (minutes)", value: Binding(get: {
                (tempItem.runTimeTicks ?? 0) / 600_000_000
            }, set: {
                tempItem.runTimeTicks = $0 * 600_000_000
            }), formatter: NumberFormatter())
        }
    }

    private var endDateSection: some View {
        Section("End Date") {
            DatePicker("End Date", selection: Binding(get: {
                tempItem.endDate ?? Date()
            }, set: {
                tempItem.endDate = $0
            }), displayedComponents: .date)
        }
    }

    private var criticRatingSection: some View {
        Section("Ratings") {
            TextField("Critic Rating", value: Binding(get: {
                tempItem.criticRating ?? 0.0
            }, set: {
                tempItem.criticRating = $0
            }), formatter: NumberFormatter())
        }
    }

    private var seriesSpecificSection: some View {
        Section("Series Specific") {
            Picker("Status", selection: Binding(get: {
                tempItem.status ?? ""
            }, set: {
                tempItem.status = $0
            })) {
                Text("Continuing").tag("Continuing")
                Text("Ended").tag("Ended")
                Text("Unreleased").tag("Unreleased")
            }

            TextField("Air Time", text: Binding(get: {
                tempItem.airTime ?? ""
            }, set: {
                tempItem.airTime = $0
            }))
        }
    }

    private var albumArtistSection: some View {
        Section("Album Artists") {
            // Add album artist-related fields here
        }
    }

    private var artistAndAlbumSection: some View {
        Section("Artist & Album") {
            TextField("Album", text: Binding(get: {
                tempItem.album ?? ""
            }, set: {
                tempItem.album = $0
            }))
        }
    }

    private var displayOrderSectionBoxSet: some View {
        Section("Display Order (Box Set)") {
            Picker("Display Order", selection: Binding(get: {
                tempItem.displayOrder ?? ""
            }, set: {
                tempItem.displayOrder = $0
            })) {
                Text("Date Modified").tag("DateModified")
                Text("Sort Name").tag("SortName")
                Text("Premiere Date").tag("PremiereDate")
            }
        }
    }

    private var displayOrderSectionSeries: some View {
        Section("Display Order (Series)") {
            Picker("Display Order", selection: Binding(get: {
                tempItem.displayOrder ?? ""
            }, set: {
                tempItem.displayOrder = $0
            })) {
                Text("Aired").tag("Aired")
                Text("Original Air Date").tag("originalAirDate")
                Text("Absolute").tag("absolute")
                Text("DVD").tag("dvd")
                Text("Digital").tag("digital")
                Text("Story Arc").tag("storyArc")
                Text("Production").tag("production")
                Text("TV").tag("tv")
                Text("Alternate").tag("alternate")
                Text("Regional").tag("regional")
                Text("Alternate DVD").tag("altdvd")
            }
        }
    }

    // MARK: - Save Logic

    private func saveIfNeeded() {
        if viewModel.item != tempItem {
            // Perform save action if changes are detected
        }
    }
}

struct LanguagePicker: View {
    let title: String
    @Binding
    var selectedLanguageCode: String?

    private var languages: [(code: String?, name: String)] {
        var uniqueLanguages = Set<String>()

        var languageList: [(code: String?, name: String)] = Locale.availableIdentifiers.compactMap { identifier in
            let locale = Locale(identifier: identifier)
            if let code = locale.languageCode,
               let name = locale.localizedString(forLanguageCode: code),
               !uniqueLanguages.contains(code)
            {
                uniqueLanguages.insert(code)
                return (code, name)
            }
            return nil
        }
        .sorted { $0.name < $1.name }

        // Add None as an option at the top of the list
        languageList.insert((code: nil, name: L10n.none), at: 0)
        return languageList
    }

    var body: some View {
        Picker(title, selection: $selectedLanguageCode) {
            ForEach(languages, id: \.code) { language in
                Text(language.name).tag(language.code)
            }
        }
    }
}

struct CountryPicker: View {
    let title: String
    @Binding
    var selectedCountryCode: String?

    private var countries: [(code: String?, name: String)] {
        var uniqueCountries = Set<String>()

        var countryList: [(code: String?, name: String)] = Locale.isoRegionCodes.compactMap { code in
            let locale = Locale(identifier: "en_US")
            if let name = locale.localizedString(forRegionCode: code),
               !uniqueCountries.contains(code)
            {
                uniqueCountries.insert(code)
                return (code, name)
            }
            return nil
        }
        .sorted { $0.name < $1.name }

        // Add None as an option at the top of the list
        countryList.insert((code: nil, name: L10n.none), at: 0)
        return countryList
    }

    var body: some View {
        Picker(title, selection: $selectedCountryCode) {
            ForEach(countries, id: \.code) { country in
                Text(country.name).tag(country.code)
            }
        }
    }
}
