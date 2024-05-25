//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LetterPickerBar: View {

    @ObservedObject
    var viewModel: FilterViewModel
    private var onSelect: (FilterCoordinator.Parameters) -> Void

    enum Orientation: String, CaseIterable, Defaults.Serializable, Displayable {

        case none
        case leading
        case trailing

        var displayTitle: String {
            switch self {
            case .none:
                return L10n.none
            case .leading:
                return L10n.left
            case .trailing:
                return L10n.right
            }
        }
    }

    @ViewBuilder
    private var letterPickerBody: some View {
        VStack(spacing: 0) {
            ForEach(ItemLetter.allCases, id: \.self) { filterLetter in
                LetterPickerButton(
                    filterLetter: filterLetter.value,
                    activated: viewModel.currentFilters.letter.contains { $0.value == filterLetter.value },
                    viewModel: viewModel
                )
            }
        }
    }

    var body: some View {
        Group {
            if ItemLetter.allCases.count > 27 {
                ScrollView(showsIndicators: false) {
                    letterPickerBody
                        .frame(maxWidth: .infinity)
                }
                .padding(1)
            } else {
                letterPickerBody
            }
        }
        .frame(width: 40)
    }
}

extension LetterPickerBar {
    init(viewModel: FilterViewModel) {
        self.viewModel = viewModel
        self.onSelect = { _ in }
    }

    func onSelect(_ action: @escaping (FilterCoordinator.Parameters) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
