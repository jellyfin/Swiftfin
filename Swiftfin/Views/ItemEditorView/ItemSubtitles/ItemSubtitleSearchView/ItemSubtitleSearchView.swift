//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: Localize

struct ItemSubtitleSearchView: View {

    // MARK: - Environment & Observed Objects

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @ObservedObject
    private var viewModel: ItemSubtitlesViewModel

    // MARK: - Selected Subtitles

    @State
    private var selectedSubtitles: Set<String> = []

    // MARK: - Search Properties

    @State
    private var language: String?
    @State
    private var isPerfectMatch = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: ItemSubtitlesViewModel) {
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
        .navigationBarTitle(L10n.search)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            language = nil
        }
        .errorMessage($error)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
        .topBarTrailing {
            if viewModel.backgroundStates.isNotEmpty {
                ProgressView()
            }
            Button(L10n.save) {
                setSubtitles()
            }
            .buttonStyle(.toolbarPill)
            .disabled(selectedSubtitles.isEmpty)
        }
    }

    // MARK: - Content View

    private var contentView: some View {
        Form {
            searchSection
            resultsSection
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        Section(L10n.options) {
            LanguagePicker(title: L10n.language, selectedLanguageCode: $language)
                .onChange(of: language) { _ in
                    if let language {
                        viewModel.send(.search(language: language, isPerfectMatch: isPerfectMatch))
                    }
                }

            Toggle("Perfect Match", isOn: $isPerfectMatch)
                .onChange(of: isPerfectMatch) { _ in
                    if let language {
                        viewModel.send(.search(language: language, isPerfectMatch: isPerfectMatch))
                    }
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
                SubtitleResultRow(subtitle: subtitle) {
                    if let subtitleID = subtitle.id {
                        if selectedSubtitles.contains(subtitleID) {
                            selectedSubtitles.remove(subtitleID)
                        } else {
                            selectedSubtitles.insert(subtitleID)
                        }
                    }
                }
                .foregroundStyle(selectedSubtitles.contains(subtitle.id ?? "") ? .primary : .secondary, .secondary)
                .environment(\.isSelected, selectedSubtitles.contains(subtitle.id ?? ""))
                .environment(\.isEditing, true)
            }
        }
    }

    // MARK: - Set Subtitles

    private func setSubtitles() {
        guard selectedSubtitles.isNotEmpty else {
            error = JellyfinAPIError("No subtitle selected")
            return
        }

        viewModel.send(.set(selectedSubtitles))

        router.dismissCoordinator()
    }
}
