//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CulturePicker: View {

    // MARK: - State Objects

    @StateObject
    private var viewModel: CulturesViewModel

    // MARK: - Input Properties

    private var selectionBinding: Binding<CultureDto?>
    private let title: String

    @State
    private var selection: CultureDto?

    // MARK: - Body

    var body: some View {
        Group {
            #if os(tvOS)
            ListRowMenu(title, subtitle: $selection.wrappedValue?.displayTitle) {
                Picker(title, selection: $selection) {
                    Text(CultureDto.none.displayTitle)
                        .tag(CultureDto.none as CultureDto?)

                    ForEach(viewModel.value, id: \.self) { value in
                        Text(value.displayTitle)
                            .tag(value as CultureDto?)
                    }
                }
            }
            // TODO: iOS 17+ move this to the Group
            .onChange(of: viewModel.value) {
                updateSelection()
            }
            .onChange(of: selection) { _, newValue in
                selectionBinding.wrappedValue = newValue
            }
            .menuStyle(.borderlessButton)
            .listRowInsets(.zero)
            #else
            Picker(title, selection: $selection) {

                Text(CultureDto.none.displayTitle)
                    .tag(CultureDto.none as CultureDto?)

                ForEach(viewModel.value, id: \.self) { value in
                    Text(value.displayTitle)
                        .tag(value as CultureDto?)
                }
            }
            // TODO: iOS 17+ delete this and use the tvOS onChange at the Group level
            .onChange(of: viewModel.value) { _ in
                updateSelection()
            }
            .onChange(of: selection) { newValue in
                selectionBinding.wrappedValue = newValue
            }
            #endif
        }
        .onFirstAppear {
            viewModel.refresh()
        }
    }

    private func updateSelection() {
        let newValue = viewModel.value.first { value in
            if let selectedTwo = selection?.twoLetterISOLanguageName,
               let candidateTwo = value.twoLetterISOLanguageName,
               selectedTwo == candidateTwo
            {
                return true
            }
            if let selectedThree = selection?.threeLetterISOLanguageName,
               let candidateThree = value.threeLetterISOLanguageName,
               selectedThree == candidateThree
            {
                return true
            }
            return false
        }

        selection = newValue ?? CultureDto.none
    }
}

extension CulturePicker {

    init(_ title: String, twoLetterISOLanguageName: Binding<String?>) {
        self.title = title
        self._selection = State(
            initialValue: twoLetterISOLanguageName.wrappedValue.flatMap {
                CultureDto(twoLetterISOLanguageName: $0)
            } ?? CultureDto.none
        )

        self.selectionBinding = Binding<CultureDto?>(
            get: {
                guard let code = twoLetterISOLanguageName.wrappedValue else {
                    return CultureDto.none
                }
                return CultureDto(twoLetterISOLanguageName: code)
            },
            set: { newCountry in
                twoLetterISOLanguageName.wrappedValue = newCountry?.twoLetterISOLanguageName
            }
        )

        self._viewModel = StateObject(
            wrappedValue: CulturesViewModel(
                initialValue: [.none]
            )
        )
    }

    init(_ title: String, threeLetterISOLanguageName: Binding<String?>) {
        self.title = title
        self._selection = State(
            initialValue: threeLetterISOLanguageName.wrappedValue.flatMap {
                CultureDto(threeLetterISOLanguageName: $0)
            } ?? CultureDto.none
        )

        self.selectionBinding = Binding<CultureDto?>(
            get: {
                guard let code = threeLetterISOLanguageName.wrappedValue else {
                    return CultureDto.none
                }
                return CultureDto(threeLetterISOLanguageName: code)
            },
            set: { newCountry in
                threeLetterISOLanguageName.wrappedValue = newCountry?.threeLetterISOLanguageName
            }
        )

        self._viewModel = StateObject(
            wrappedValue: CulturesViewModel(
                initialValue: [.none]
            )
        )
    }
}
