//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct RandomItemButton: View {

    @ObservedObject
    private var viewModel: PagingLibraryViewModel
    private var onSelect: (BaseItemDtoQueryResult) -> Void

    var body: some View {
        Button {
            Task {
                let response = try await viewModel.getRandomItemFromLibrary()
                onSelect(response)
            }
        } label: {
            Label(L10n.random, systemImage: "dice.fill")
        }
    }
}

extension RandomItemButton {
    init(viewModel: PagingLibraryViewModel) {
        self.init(
            viewModel: viewModel,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (BaseItemDtoQueryResult) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
