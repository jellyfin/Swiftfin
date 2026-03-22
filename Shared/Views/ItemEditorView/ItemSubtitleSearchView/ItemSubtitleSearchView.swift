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

    @State
    private var isPerfectMatch = false

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
        .backport
        .onChange(of: isPerfectMatch) { _, newValue in
            viewModel.searchParameters.value = newValue
        }
    }

    @ViewBuilder
    private var contentView: some View {
        Form(systemImage: "textformat") {

            Section(L10n.options) {
                CulturePicker(L10n.language, threeLetterISOLanguageName: $viewModel.language)

                Toggle(L10n.perfectMatch, isOn: $isPerfectMatch)
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
                    if viewModel.background.is(.searching) {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text(L10n.none)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    ForEach(viewModel.searchResults, id: \.id) { subtitle in
                        SearchResultRow(subtitle) {
                            guard let subtitleID = subtitle.id else { return }
                            selectedSubtitles.toggle(value: subtitleID)
                        }
                        .isSelected(subtitle.id.map { selectedSubtitles.contains($0) } == true)
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
}
