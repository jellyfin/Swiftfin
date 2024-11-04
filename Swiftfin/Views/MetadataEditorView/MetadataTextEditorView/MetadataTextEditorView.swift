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

struct MetadataTextEditorView: View {

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @State
    private var tempItem: BaseItemDto

    @ObservedObject
    private var viewModel: UpdateMetadataViewModel

    private let itemType: BaseItemKind

    init(item: BaseItemDto) {
        self.itemType = item.type!
        self.viewModel = UpdateMetadataViewModel(item: item)
        _tempItem = State(initialValue: item)
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        Form {

            // MARK: - Sections that should exist for all items

            BaseItemSection(
                item: $tempItem,
                itemType: itemType
            )

            // MARK: - Sections for localization metadata

            LocalizationSection(item: $tempItem)

            // MARK: - Sections for series items

            if itemType == .series {
                SeriesSection(item: $tempItem)
            }

            // MARK: - Sections for parential ratings

            ParentalRatingSection(item: $tempItem)

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

            // MARK: - Sections for locking metadata sections

            LockMetadataSection(item: $tempItem)
        }
        .navigationBarTitle("Edit Metadata", displayMode: .inline)
        .topBarTrailing {
            Button(L10n.save) {
                viewModel.send(.update(tempItem))
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.item == tempItem)
        }
        .navigationBarCloseButton {
            router.dismissCoordinator()
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
}
