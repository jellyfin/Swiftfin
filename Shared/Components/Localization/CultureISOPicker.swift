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
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        if viewModel.cultures.isEmpty {
            Text(L10n.none)
                .foregroundStyle(.secondary)
        } else {

            let cultures = availableCultures

            /// Create a binding to the index in the array
            let indexBinding = Binding<Int>(
                get: {
                    /// Primary - Try to find by selected culture
                    if let selectedCulture = selectedCulture {
                        for (index, culture) in cultures.enumerated() {
                            if getThreeLetterCode(from: culture) == getThreeLetterCode(from: selectedCulture) {
                                return index
                            }
                        }
                    }

                    /// Secondary - Try by 2 letter language code
                    if let languageCode = twoLetterISOLanguage {
                        for (index, culture) in cultures.enumerated() {
                            if let code = getTwoLetterCode(from: culture),
                               code == languageCode
                            {
                                return index
                            }
                        }
                    }

                    /// Tertiary - Try by 3 letter language code
                    if let languageCode = threeLetterISOLanguage {
                        for (index, culture) in cultures.enumerated() {
                            if let code = getThreeLetterCode(from: culture),
                               code == languageCode
                            {
                                return index
                            }
                        }
                    }
                    return 0
                },
                set: { newIndex in
                    if newIndex >= 0 && newIndex < cultures.count {
                        let culture = cultures[newIndex]
                        twoLetterISOLanguage = getTwoLetterCode(from: culture)
                        threeLetterISOLanguage = getThreeLetterCode(from: culture)
                        selectedCulture = culture
                    }
                }
            )

            isoPicker(title, selection: indexBinding)
        }
    }

    // MARK: - Picker by Platform

    @ViewBuilder
    private func isoPicker(_ title: String, selection: Binding<Int>) -> some View {
        #if os(tvOS)
        ListRowMenu(title, subtitle: {
            Text(getDisplayName(for: availableCultures[selection.wrappedValue]))
        }) {
            ForEach(cultures.indices, id: \.self) { index in
                let country = availableCultures[index]
                Button(getDisplayName(for: country)) {
                    selection.wrappedValue = index
                }
            }
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
        #else
        Picker(title, selection: selection) {
            ForEach(0 ..< availableCultures.count, id: \.self) { index in
                Text(getDisplayName(for: availableCultures[index]))
                    .tag(index)
            }
        }
        #endif
    }

    // MARK: - Get Available Localizations

    private var availableCultures: [CultureDto] {
        // TODO: Remove after iOS15 dropped
        /// Return only Jellyfin-provided cultures on pre-iOS 16
        guard #available(iOS 16, *) else {
            return [emptyCultureDto] + viewModel.cultures
                .sorted { getDisplayName(for: $0) < getDisplayName(for: $1) }
        }

        let jellyfinCultures = viewModel.cultures
        let existingTwoLetterCodes = Set(jellyfinCultures.compactMap(\.twoLetterISOLanguageName))
        let existingThreeLetterCodes = Set(jellyfinCultures.compactMap(\.threeLetterISOLanguageName))

        let systemCulturesDict = Locale.availableIdentifiers.reduce(into: [String: CultureDto]()) { dict, identifier in
            let locale = Locale(identifier: identifier)

            guard let code = locale.language.languageCode?.identifier,
                  let threeLetterCode = locale.language.languageCode?.identifier(.alpha3),
                  let twoLetterCode = locale.language.languageCode?.identifier(.alpha2),
                  let displayName = Locale.current.localizedString(forIdentifier: code),
                  !dict.keys.contains(twoLetterCode), /// Check if we've already processed this language
                  !(existingTwoLetterCodes.contains(twoLetterCode) && existingThreeLetterCodes.contains(threeLetterCode))
            else { return }

            dict[twoLetterCode] = CultureDto(
                displayName: displayName,
                name: code,
                threeLetterISOLanguageName: threeLetterCode,
                threeLetterISOLanguageNames: [threeLetterCode],
                twoLetterISOLanguageName: twoLetterCode
            )
        }

        return [emptyCultureDto] + (jellyfinCultures + Array(systemCulturesDict.values))
            .sorted { getDisplayName(for: $0) < getDisplayName(for: $1) }
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

    // MARK: - Get 3 Letter ISO with Fallbacks

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
