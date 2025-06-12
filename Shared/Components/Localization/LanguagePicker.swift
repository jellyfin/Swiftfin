//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LanguagePicker: View {

    // MARK: - State Objects

    @StateObject
    private var viewModel = CultureViewModel()

    // MARK: - State Variables

    @State
    private var selectedIndex: Int = 0

    // MARK: - Computed Properties

    private var cultures: [CultureDto] {
        [emptyCultureDto] + Array(viewModel.cultures)
            .sorted { getDisplayName(for: $0) < getDisplayName(for: $1) }
    }

    // MARK: - Input Properties

    private let title: String

    @Binding
    private var selectedCulture: CultureDto?

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .refreshing:
                ProgressView()
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .onChange(of: viewModel.cultures) { _ in
            upgradeSelectedCultureIfNeeded()
            updateSelectedIndex()
        }
        .onChange(of: selectedCulture) { _ in
            updateSelectedIndex()
        }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        if cultures.isEmpty {
            Text(L10n.none)
                .foregroundStyle(.secondary)
        } else {
            isoPicker(title, cultures: cultures, selection: $selectedIndex)
                .onChange(of: selectedIndex) { newIndex in
                    if newIndex >= 0 && newIndex < cultures.count {
                        selectedCulture = cultures[newIndex]
                    }
                }
        }
    }

    // MARK: - ISO Picker

    @ViewBuilder
    private func isoPicker(_ title: String, cultures: [CultureDto], selection: Binding<Int>) -> some View {
        #if os(tvOS)
        ListRowMenu(title, subtitle: {
            Text(getDisplayName(for: cultures[selection.wrappedValue]))
        }) {
            ForEach(cultures.indices, id: \.self) { index in
                let culture = cultures[index]
                Button(getDisplayName(for: culture)) {
                    selection.wrappedValue = index
                }
            }
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
        #else
        Picker(title, selection: selection) {
            ForEach(0 ..< cultures.count, id: \.self) { index in
                Text(getDisplayName(for: cultures[index]))
                    .tag(index)
            }
        }
        #endif
    }

    // MARK: Update the Selected Index

    private func updateSelectedIndex() {
        guard !cultures.isEmpty else { return }

        if let selectedCulture = selectedCulture {
            let matchingCulture = findMatchingCulture(for: selectedCulture)
            selectedIndex = cultures.firstIndex(where: { areEqual($0, matchingCulture) }) ?? 0
        } else {
            selectedIndex = 0
        }
    }

    // MARK: Turn Incomplete CultureDto into Full Matching CultureDto

    private func upgradeSelectedCultureIfNeeded() {
        guard let currentSelected = selectedCulture else { return }

        if let upgradeCandidate = findMatchingCulture(for: currentSelected),
           !areEqual(upgradeCandidate, currentSelected)
        {
            selectedCulture = upgradeCandidate
        }
    }

    // MARK: - Find a Matching CultureDto from Potentially Incomplete CultureDto

    private func findMatchingCulture(for culture: CultureDto) -> CultureDto? {
        cultures.first { candidate in
            if let selectedTwo = culture.twoLetterISOLanguageName,
               let candidateTwo = candidate.twoLetterISOLanguageName,
               selectedTwo == candidateTwo
            {
                return true
            }
            if let selectedThree = culture.threeLetterISOLanguageName,
               let candidateThree = candidate.threeLetterISOLanguageName,
               selectedThree == candidateThree
            {
                return true
            }
            return false
        }
    }

    // MARK: - Determine if Two Cultures are Equal from Potentially Incomplete CultureDto

    private func areEqual(_ culture1: CultureDto?, _ culture2: CultureDto?) -> Bool {
        guard let culture1 = culture1, let culture2 = culture2 else {
            return culture1 == nil && culture2 == nil
        }

        return culture1.twoLetterISOLanguageName == culture2.twoLetterISOLanguageName &&
            culture1.threeLetterISOLanguageName == culture2.threeLetterISOLanguageName
    }

    // MARK: - Get Culture Display Name

    private func getDisplayName(for culture: CultureDto) -> String {
        culture.displayName ?? culture.name ?? L10n.unknown
    }

    // MARK: - Empty Culture DTO

    private var emptyCultureDto: CultureDto {
        .init(
            displayName: L10n.none,
            name: L10n.none,
            threeLetterISOLanguageName: nil,
            threeLetterISOLanguageNames: [],
            twoLetterISOLanguageName: nil
        )
    }
}

extension LanguagePicker {

    // MARK: - Standard Initializer

    init(_ title: String, selectedCulture: Binding<CultureDto?>) {
        self.title = title
        self._selectedCulture = selectedCulture
    }

    // MARK: - Two Letter Initializer

    init(_ title: String, twoLetterISOLanguage: Binding<String?>) {
        self.title = title
        self._selectedCulture = Binding(
            get: {
                guard let code = twoLetterISOLanguage.wrappedValue else { return nil }
                return CultureDto(
                    displayName: nil,
                    name: nil,
                    threeLetterISOLanguageName: nil,
                    threeLetterISOLanguageNames: [],
                    twoLetterISOLanguageName: code
                )
            },
            set: { newCulture in
                twoLetterISOLanguage.wrappedValue = newCulture?.twoLetterISOLanguageName
            }
        )
    }

    // MARK: - Three Letter Initializer

    init(_ title: String, threeLetterISOLanguage: Binding<String?>) {
        self.title = title
        self._selectedCulture = Binding(
            get: {
                guard let code = threeLetterISOLanguage.wrappedValue else { return nil }
                return CultureDto(
                    displayName: nil,
                    name: nil,
                    threeLetterISOLanguageName: code,
                    threeLetterISOLanguageNames: [],
                    twoLetterISOLanguageName: nil
                )
            },
            set: { newCulture in
                threeLetterISOLanguage.wrappedValue = newCulture?.threeLetterISOLanguageName
            }
        )
    }
}
