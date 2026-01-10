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

    // MARK: - Accent Color

    @Default(.accentColor)
    private var accentColor

    // MARK: - Router

    @Router
    private var router

    // MARK: - ViewModel

    @ObservedObject
    private var viewModel: SubtitleEditorViewModel

    // MARK: - Selected Subtitles

    @State
    private var selectedSubtitles: Set<String> = []

    // MARK: - Search Properties

    /// Default to user's language
    @State
    private var language: String? = Locale.current.language.languageCode?.identifier(.alpha3)
    @State
    private var isPerfectMatch = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: SubtitleEditorViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            BlurView()
                .ignoresSafeArea()
            contentView
        }
        .navigationTitle(L10n.search)
        .onFirstAppear {
            viewModel.send(.search(language: language))
        }
        .topBarTrailing {
            if viewModel.backgroundStates.isNotEmpty {
                ProgressView()
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted:
                return
            case .uploaded:
                router.dismiss()
            case let .error(eventError):
                error = eventError
            }
        }
        .errorMessage($error)
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .initial, .content:
            searchView
        case let .error(error):
            ErrorView(error: error)
        }
    }

    // MARK: - Search View

    private var searchView: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "textformat")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                searchSection
                resultsSection
            }
    }

    // MARK: - Search Section

    @ViewBuilder
    private var searchSection: some View {
        Section(L10n.options) {
            CulturePicker(L10n.language, threeLetterISOLanguageName: $language)
                .onChange(of: language) {
                    guard let language else { return }
                    viewModel.send(.search(language: language, isPerfectMatch: isPerfectMatch))
                }

            Toggle(L10n.perfectMatch, isOn: $isPerfectMatch)
                .onChange(of: isPerfectMatch) {
                    guard let language else { return }
                    viewModel.send(.search(language: language, isPerfectMatch: isPerfectMatch))
                }
        }

        Section {
            if viewModel.backgroundStates.contains(.updating) {
                Button(L10n.cancel, role: .destructive) {
                    viewModel.send(.cancel)
                }
                .buttonStyle(.primary)
                .listRowInsets(.zero)
            } else {
                Button(L10n.save) {
                    setSubtitles()
                }
                .buttonStyle(.primary)
                .foregroundStyle(
                    accentColor.overlayColor,
                    accentColor
                )
                .listRowInsets(.zero)
                .disabled(selectedSubtitles.isEmpty)
            }
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        Section(L10n.search) {
            if viewModel.searchResults.isEmpty {
                Text(L10n.none)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            ForEach(viewModel.searchResults, id: \.id) { subtitle in
                let isSelected = subtitle.id.map { selectedSubtitles.contains($0) } ?? false

                SubtitleResultRow(subtitle: subtitle) {
                    guard let subtitleID = subtitle.id else { return }
                    selectedSubtitles.toggle(value: subtitleID)
                }
                .foregroundStyle(isSelected ? .primary : .secondary, .secondary)
                .isSelected(isSelected)
                .isEditing(true)
            }
        }
    }

    // MARK: - Set Subtitles

    private func setSubtitles() {
        guard selectedSubtitles.isNotEmpty else {
            error = ErrorMessage(L10n.noItemSelected)
            return
        }

        viewModel.send(.set(selectedSubtitles))
    }
}
