//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CulturePicker: View {

    @StateObject
    private var viewModel: CulturesViewModel

    private let selection: Binding<String?>
    private let title: String
    private let isUsingTwoLetterISO: Bool

    init(_ title: String, twoLetterISOLanguageName: Binding<String?>) {
        self.selection = twoLetterISOLanguageName
        self.title = title
        self._viewModel = .init(wrappedValue: .init(initialValue: []))
        self.isUsingTwoLetterISO = true
    }

    init(_ title: String, threeLetterISOLanguageName: Binding<String?>) {
        self.selection = threeLetterISOLanguageName
        self.title = title
        self._viewModel = .init(wrappedValue: .init(initialValue: []))
        self.isUsingTwoLetterISO = false
    }

    private var currentCulture: CultureDto? {
        if isUsingTwoLetterISO {
            return viewModel.value.first(property: \.twoLetterISOLanguageName, equalTo: selection.wrappedValue)
        } else {
            return viewModel.value.first(property: \.threeLetterISOLanguageName, equalTo: selection.wrappedValue)
        }
    }

    @ViewBuilder
    private var picker: some View {
        let _selection = {
            if isUsingTwoLetterISO {
                selection.map(
                    getter: { iso in viewModel.value.first(property: \.twoLetterISOLanguageName, equalTo: iso) },
                    setter: { $0?.twoLetterISOLanguageName }
                )
            } else {
                selection.map(
                    getter: { iso in viewModel.value.first(property: \.threeLetterISOLanguageName, equalTo: iso) },
                    setter: { $0?.threeLetterISOLanguageName }
                )
            }
        }()

        Picker(
            title,
            sources: viewModel.value,
            selection: _selection
        )
    }

    var body: some View {
        Group {
            #if os(tvOS)
            ListRowMenu(
                title,
                subtitle: currentCulture?.displayTitle
            ) {
                picker
            }
            .menuStyle(.borderlessButton)
            .listRowInsets(.zero)
            #else
            picker
            #endif
        }
        .enabled(viewModel.state == .initial)
        .onFirstAppear {
            viewModel.refresh()
        }
    }
}
