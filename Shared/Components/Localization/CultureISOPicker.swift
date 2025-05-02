//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CultureISOPicker: View {

    // MARK: - State Object

    @StateObject
    private var viewModel = CultureViewModel()

    // MARK: - Selection State

    @State
    private var selectedIndex: Int = 0

    // MARK: - Cultures List

    private var cultures: [CultureDto] {
        [emptyCultureDto] + Array(viewModel.cultures)
            .sorted { getDisplayName(for: $0) < getDisplayName(for: $1) }
    }

    // MARK: - Picker Title

    private let title: String

    // MARK: - ISO Language Codes

    @Binding
    private var twoLetterISOLanguage: String?
    @Binding
    private var threeLetterISOLanguage: String?

    // MARK: - Selected Culture

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
            updateSelectedIndex()
        }
        .onChange(of: selectedCulture) { _ in
            updateSelectedIndex()
        }
        .onChange(of: twoLetterISOLanguage) { _ in
            updateSelectedIndex()
        }
        .onChange(of: threeLetterISOLanguage) { _ in
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
                        let culture = cultures[newIndex]
                        twoLetterISOLanguage = getTwoLetterCode(from: culture)
                        threeLetterISOLanguage = getThreeLetterCode(from: culture)
                        selectedCulture = culture
                    }
                }
        }
    }

    // MARK: - Picker by Platform

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

    // MARK: - Update Selection

    private func updateSelectedIndex() {
        guard !cultures.isEmpty else { return }

        var twoLetterMap: [String: Int] = [:]
        var threeLetterMap: [String: Int] = [:]

        for (index, culture) in cultures.enumerated() {
            if let code = getTwoLetterCode(from: culture) {
                twoLetterMap[code] = index
            }
            if let code = getThreeLetterCode(from: culture) {
                threeLetterMap[code] = index
            }
        }

        // Try to find by selected culture
        if let selectedCulture = selectedCulture {
            if let twoLetter = getTwoLetterCode(from: selectedCulture),
               let threeLetter = getThreeLetterCode(from: selectedCulture)
            {
                // Look for exact match with both codes
                for (index, culture) in cultures.enumerated() {
                    if getTwoLetterCode(from: culture) == twoLetter &&
                        getThreeLetterCode(from: culture) == threeLetter
                    {
                        selectedIndex = index
                        return
                    }
                }
            }

            // Try just two letter code
            if let twoLetter = getTwoLetterCode(from: selectedCulture),
               let index = twoLetterMap[twoLetter]
            {
                selectedIndex = index
                return
            }

            // Try just three letter code
            if let threeLetter = getThreeLetterCode(from: selectedCulture),
               let index = threeLetterMap[threeLetter]
            {
                selectedIndex = index
                return
            }
        }

        // Try by two letter language code
        if let code = twoLetterISOLanguage, let index = twoLetterMap[code] {
            selectedIndex = index
            return
        }

        // Try by three letter language code
        if let code = threeLetterISOLanguage, let index = threeLetterMap[code] {
            selectedIndex = index
            return
        }

        // Default to first item
        selectedIndex = 0
    }

    // MARK: - Get 2 Letter ISO with Fallbacks

    private func getTwoLetterCode(from culture: CultureDto) -> String? {
        culture.twoLetterISOLanguageName
    }

    // MARK: - Get 3 Letter ISO with Fallbacks

    private func getThreeLetterCode(from culture: CultureDto) -> String? {
        culture.threeLetterISOLanguageName ?? culture.threeLetterISOLanguageNames?.first
    }

    // MARK: - Get DisplayName with Fallbacks

    private func getDisplayName(for culture: CultureDto) -> String {
        culture.displayName ?? culture.name ?? L10n.unknown
    }

    // MARK: - Get Empty Culture DTO

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

extension CultureISOPicker {

    // MARK: - Initialize with CultureDto

    init(_ title: String, selectedCulture: Binding<CultureDto?>) {
        self.title = title
        self._twoLetterISOLanguage = .constant(selectedCulture.wrappedValue?.twoLetterISOLanguageName)
        self._threeLetterISOLanguage = .constant(selectedCulture.wrappedValue?.threeLetterISOLanguageName)
        self._selectedCulture = selectedCulture
    }

    // MARK: - Initialize with 2 letter ISO code

    init(_ title: String, twoLetterISOLanguage: Binding<String?>) {
        self.title = title
        self._twoLetterISOLanguage = twoLetterISOLanguage
        self._threeLetterISOLanguage = .constant(nil)
        self._selectedCulture = .constant(nil)
    }

    // MARK: - Initialize with 3 letter ISO code

    init(_ title: String, threeLetterISOLanguage: Binding<String?>) {
        self.title = title
        self._twoLetterISOLanguage = .constant(nil)
        self._threeLetterISOLanguage = threeLetterISOLanguage
        self._selectedCulture = .constant(nil)
    }
}
