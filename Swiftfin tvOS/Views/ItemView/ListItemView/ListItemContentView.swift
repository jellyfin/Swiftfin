//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ListItemView {

    struct ContentView: View {

        @ObservedObject
        var viewModel: ListItemViewModel

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        var body: some View {
            VStack(spacing: 0) {

                ItemView.CinematicHeaderView(viewModel: viewModel)
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                if viewModel.listItems.isNotEmpty {

                    ForEach(BaseItemKind.allCases, id: \.self) { sectionType in
                        let sectionItems = viewModel.listItems.filter { $0.type == sectionType }

                        if sectionItems.isNotEmpty {
                            PosterHStack(
                                // TODO: Is there a way to make this plural without creating a pluralDisplayTitle?
                                title: sectionType.displayTitle,
                                type: .portrait,
                                items: sectionItems
                            )
                            .onSelect { item in
                                router.route(to: \.item, item)
                            }

                            RowDivider()
                                .padding(24)
                        }
                    }
                }

                if viewModel.similarItems.isNotEmpty {
                    ItemView.SimilarItemsHStack(items: viewModel.similarItems)
                }

                ItemView.AboutView(viewModel: viewModel)
            }
            .background {
                BlurView(style: .dark)
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.5),
                                    .init(color: .white.opacity(0.8), location: 0.7),
                                    .init(color: .white.opacity(0.8), location: 0.95),
                                    .init(color: .white, location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: UIScreen.main.bounds.height - 150)

                            Color.white
                        }
                    }
            }
        }
    }
}
