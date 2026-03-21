//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ItemSubtitleSearchView: View {

    @Default(.accentColor)
    private var accentColor

    @Router
    private var router

    @ObservedObject
    private var viewModel: ItemSubtitlesViewModel

    @State
    private var selectedSubtitles: Set<String> = []

    init(viewModel: ItemSubtitlesViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .content:
                contentView
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            }
        }
        .navigationTitle(L10n.search)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.search()
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted:
                break
            case .uploaded:
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.states.isNotEmpty {
                ProgressView()
            }
            #if os(iOS)
            saveButton
                .buttonStyle(.toolbarPill)
            #endif
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Form(systemImage: "textformat") {

            Section(L10n.options) {
                CulturePicker(L10n.language, threeLetterISOLanguageName: $viewModel.language)

                Toggle(L10n.perfectMatch, isOn: $viewModel.isPerfectMatch)
            }

            #if os(tvOS)
            Section {
                saveButton
                    .buttonStyle(.primary)
                    .listRowInsets(.zero)
            }
            #endif

            Section(L10n.search) {

                if viewModel.searchResults.isEmpty {
                    if viewModel.background.states.contains(.searching) {
                        ProgressView()
                    } else {
                        Text(L10n.none)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    ForEach(viewModel.searchResults, id: \.id) { subtitle in
                        resultRow(subtitle: subtitle)
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button(L10n.save) {
            guard selectedSubtitles.isNotEmpty else { return }
            viewModel.set(selectedSubtitles)
        }
        .foregroundStyle(accentColor.overlayColor, accentColor)
        .disabled(selectedSubtitles.isEmpty)
    }

    @ViewBuilder
    private func resultRow(subtitle: RemoteSubtitleInfo) -> some View {

        let isSelected = subtitle.id.map { selectedSubtitles.contains($0) } == true

        Button {
            guard let subtitleID = subtitle.id else { return }
            selectedSubtitles.toggle(value: subtitleID)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subtitle.name ?? L10n.unknown)
                        .font(.headline)
                        .fontWeight(.semibold)

                    LabeledContent(L10n.language, value: subtitle.threeLetterISOLanguageName ?? L10n.unknown)

                    if let downloadCount = subtitle.downloadCount {
                        LabeledContent(L10n.downloads, value: downloadCount.description)
                    }

                    if let rating = subtitle.communityRating {
                        LabeledContent(L10n.communityRating, value: String(format: "%.1f", rating))
                    }

                    if let author = subtitle.author {
                        LabeledContent(L10n.author, value: author)
                    }

                    if let format = subtitle.format {
                        LabeledContent(L10n.format, value: format)
                    }
                }

                Spacer()

                ListRowCheckbox()
            }
            .if(UIDevice.isTV) { row in
                row
                    .padding(.vertical)
            }
        }
        .foregroundStyle(isSelected ? Color.primary : Color.secondary, Color.secondary)
        .font(.caption)
        .isSelected(isSelected)
        .isEditing(true)
    }
}
