//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Introspect
import SwiftUI

struct CinematicCollectionItemView: View {

    @EnvironmentObject
    var itemRouter: ItemCoordinator.Router
    @ObservedObject
    var viewModel: CollectionItemViewModel
    @State
    var wrappedScrollView: UIScrollView?
    @Default(.showPosterLabels)
    var showPosterLabels

    var body: some View {
        ZStack {

            ImageView(
                viewModel.item.getBackdropImage(maxWidth: 1920),
                blurHash: viewModel.item.getBackdropImageBlurHash()
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    CinematicItemViewTopRow(
                        viewModel: viewModel,
                        wrappedScrollView: wrappedScrollView,
                        title: viewModel.item.name ?? "",
                        showDetails: false
                    )
                    .focusSection()
                    .frame(height: UIScreen.main.bounds.height - 10)

                    ZStack(alignment: .topLeading) {

                        Color.black.ignoresSafeArea()

                        //						VStack(alignment: .leading, spacing: 20) {
//
                        //							CinematicItemAboutView(viewModel: viewModel)
//
                        //							PortraitImageHStack(rowTitle: L10n.items,
                        //							                     items: viewModel.collectionItems) { item in
                        //								itemRouter.route(to: \.item, item)
                        //							}
//
                        //							if !viewModel.similarItems.isEmpty {
                        //								PortraitImageHStack(rowTitle: L10n.recommended,
                        //								                     items: viewModel.similarItems,
                        //								                     showItemTitles: showPosterLabels) { item in
                        //									itemRouter.route(to: \.item, item)
                        //								}
                        //							}
                        //						}
                        //						.padding(.vertical, 50)
                    }
                }
            }
            .introspectScrollView { scrollView in
                wrappedScrollView = scrollView
            }
            .ignoresSafeArea()
        }
    }
}
