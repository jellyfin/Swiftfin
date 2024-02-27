//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct AlphaPickerBar: View {

    @ObservedObject
    var viewModel: FilterViewModel
    private var onSelect: (FilterCoordinator.Parameters) -> Void

    @ViewBuilder
    private var alphaPickerBody: some View {
        VStack(spacing: 0) {
            ForEach(AlphaPicker.characters, id: \.self) { filterLetter in
                AlphaPickerButton(
                    filterLetter: filterLetter,
                    activated: viewModel.currentFilters.alphaPicker.contains {
                        $0.id == filterLetter
                    }, viewModel: viewModel
                )
                .onSelect {
                    onSelect(.init(
                        title: L10n.letter,
                        viewModel: viewModel,
                        filter: \.alphaPicker,
                        selectorType: .single
                    ))
                }
            }
        }
    }

    var body: some View {
        Group {
            if AlphaPicker.characters.count > 27 {
                ScrollView(showsIndicators: false) {
                    alphaPickerBody
                        .frame(maxWidth: .infinity)
                }
            } else {
                alphaPickerBody
            }
        }
        .frame(width: 40)
    }
}

extension AlphaPickerBar {
    init(viewModel: FilterViewModel) {
        self.viewModel = viewModel
        self.onSelect = { _ in }
    }

    func onSelect(_ action: @escaping (FilterCoordinator.Parameters) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
