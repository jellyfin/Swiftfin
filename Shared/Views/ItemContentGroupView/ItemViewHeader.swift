//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ItemViewHeader: _ContentGroup {

    let id = "item-view-header"
    let viewModel: _ItemViewModel

    func makeViewModel() -> _ItemViewModel {
        viewModel
    }

    func body(with viewModel: _ItemViewModel) -> Body {
        Body(viewModel: viewModel)
    }

    struct Body: View {

        @Environment(\.scrollViewOffset)
        private var scrollViewOffset

        @ObservedObject
        var viewModel: _ItemViewModel

        @Router
        private var router

        private var imageType: ImageType {
            switch viewModel.item.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                .backdrop
            }
        }

        var body: some View {
            VStack {
                Color.red
                    .opacity(0.2)
                    .frame(height: 300)

                Text(viewModel.item.displayTitle)
            }
            .backgroundParallaxHeader(
                scrollViewOffset,
                multiplier: 0.3
            ) {
                AlternateLayoutView {
                    Color.clear
                } content: {
                    ImageView(viewModel.item.imageSource(.backdrop, maxWidth: 1320))
                        .aspectRatio(contentMode: .fill)
                }
                .frame(height: 300)
            }
            .trackingFrame(named: "Header")
            .preference(key: MenuContentKey.self) {
                if viewModel.userSession.user.permissions.items.canEditMetadata(item: viewModel.item) {
                    MenuContentGroup(id: "test") {
                        Button(L10n.edit, systemImage: "pencil") {
                            //                        router.route(to: .itemEditor(viewModel: viewModel))
                            router.route(to: .settings)
                        }
                    }
                }
            }
        }
    }
}
