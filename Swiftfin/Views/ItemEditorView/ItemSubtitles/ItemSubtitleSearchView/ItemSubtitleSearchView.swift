//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemSubtitleSearchView: View {

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
            switch viewModel.state {
            case .initial, .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .navigationTitle(L10n.search)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.send(.search(language: language))
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
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.backgroundStates.isNotEmpty {
                ProgressView()
            }
            if viewModel.backgroundStates.contains(.updating) {
                Button(L10n.cancel, role: .cancel) {
                    viewModel.send(.cancel)
                }
                .buttonStyle(.toolbarPill)
            } else {
                Button(L10n.save) {
                    guard selectedSubtitles.isNotEmpty else {
                        error = ErrorMessage(L10n.noItemSelected)
                        return
                    }

                    viewModel.send(.set(selectedSubtitles))
                }
                .buttonStyle(.toolbarPill)
                .disabled(selectedSubtitles.isEmpty)
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        Form {
            searchSection
            resultsSection
        }
    }

    // MARK: - Search Section

    @ViewBuilder
    private var searchSection: some View {
        Section(L10n.options) {
            CulturePicker(L10n.language, threeLetterISOLanguageName: $language)
                .onChange(of: language) { _ in
                    if let language {
                        viewModel.send(.search(language: language, isPerfectMatch: isPerfectMatch))
                    }
                }

            Toggle(L10n.perfectMatch, isOn: $isPerfectMatch)
                .onChange(of: isPerfectMatch) { _ in
                    if let language {
                        viewModel.send(.search(language: language, isPerfectMatch: isPerfectMatch))
                    }
                }
        }
    }

    // MARK: - Results Section

    @ViewBuilder
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
                    guard let subtitleID = subtitle.id else {
                        return
                    }

                    selectedSubtitles.toggle(value: subtitleID)
                }
                .foregroundStyle(isSelected ? .primary : .secondary, .secondary)
                .isSelected(isSelected)
                .isEditing(true)
            }
        }
    }
}
