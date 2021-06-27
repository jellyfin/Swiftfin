/* JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI

struct SeriesItemView: View {
    @StateObject var viewModel: SeriesItemViewModel

    @State private var tracks: [GridItem] = Array(repeating: .init(.flexible()), count: Int(UIScreen.main.bounds.size.width) / 125)

    func recalcTracks() {
        tracks = Array(repeating: .init(.flexible()), count: Int(UIScreen.main.bounds.size.width) / 125)
    }

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            ScrollView(.vertical) {
                Spacer().frame(height: 16)
                LazyVGrid(columns: tracks) {
                    ForEach(viewModel.seasons, id: \.id) { season in
                        PortraitItemView(item: season)
                    }
                    Spacer().frame(height: 2)
                }.onRotate { _ in
                    recalcTracks()
                }
            }
            .overrideViewPreference(.unspecified)
            .navigationTitle(viewModel.item.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
