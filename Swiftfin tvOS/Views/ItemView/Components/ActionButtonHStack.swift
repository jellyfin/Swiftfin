//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct ActionButtonHStack: View {

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            HStack {
                Button {
                    viewModel.toggleWatchState()
                } label: {
                    Group {
                        if viewModel.isPlayed {
                            Image(systemName: "checkmark.circle.fill")
                                .paletteOverlayRendering(color: .white)
                        } else {
                            Image(systemName: "checkmark.circle")
                        }
                    }
                    .font(.title3)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.toggleFavoriteState()
                } label: {
                    Group {
                        if viewModel.isFavorited {
                            Image(systemName: "heart.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .pink)
                        } else {
                            Image(systemName: "heart.circle")
                        }
                    }
                    .font(.title3)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
