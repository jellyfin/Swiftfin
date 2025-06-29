//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import OrderedCollections
import SwiftUI

extension ItemView {

    struct PersonItemContentView: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: PersonItemViewModel

        var body: some View {
            VStack(spacing: 0) {

                ItemView.CinematicHeaderView(viewModel: viewModel)
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                // MARK: - Items

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
