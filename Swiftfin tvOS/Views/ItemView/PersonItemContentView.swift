//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct PersonItemContentView: View {

        @ObservedObject
        var viewModel: CollectionItemViewModel

        var body: some View {
            VStack(spacing: 0) {
                ForEach(
                    viewModel.sections.elements,
                    id: \.key
                ) { element in
                    ItemTypeCollectionHStack(element: element)
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
