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
            /// Convert to array for indexed access
            let culturesArray = [emptyCultureDto] + Array(viewModel.cultures)
                .sorted { getDisplayName(for: $0) < getDisplayName(for: $1) }

            /// Create a binding to the INDEX in the array
            let indexBinding = Binding<Int>(
                get: {
                    /// Primary - Try to find by selected culture
                    if let selectedCulture = selectedCulture {
                        for (index, culture) in culturesArray.enumerated() {
                            if getThreeLetterCode(from: culture) == getThreeLetterCode(from: selectedCulture) {
                                return index
                            }
                        }
                    }

                    /// Secondary - Try by 2 letter language code
                    if let languageCode = twoLetterISOLanguage {
                        for (index, culture) in culturesArray.enumerated() {
                            if let code = getTwoLetterCode(from: culture),
                               code == languageCode
                            {
                                return index
                            }
                        }
                    }

                    /// Tertiary - Try by 3 letter language code
                    if let languageCode = threeLetterISOLanguage {
                        for (index, culture) in culturesArray.enumerated() {
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
                    if newIndex >= 0 && newIndex < culturesArray.count {
                        let culture = culturesArray[newIndex]
                        twoLetterISOLanguage = getTwoLetterCode(from: culture)
                        threeLetterISOLanguage = getThreeLetterCode(from: culture)
                        selectedCulture = culture
                    }
                }
            )

            Picker(title, selection: indexBinding) {
                ForEach(0 ..< culturesArray.count, id: \.self) { index in
                    let culture = culturesArray[index]
                    Text(getDisplayName(for: culture))
                        .tag(index)
                }
            }
        }
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
