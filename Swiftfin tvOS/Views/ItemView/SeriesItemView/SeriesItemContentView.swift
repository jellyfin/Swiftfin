//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

extension SeriesItemView {

    struct ContentView: View {

        @ObservedObject
        private var focusGuide = FocusGuide()
        @ObservedObject
        var viewModel: SeriesItemViewModel

        var body: some View {
            VStack(spacing: 0) {

                ItemView.CinematicHeaderView(viewModel: viewModel)
                    .focusGuide(focusGuide, tag: "top", bottom: "seasons")
                    .frame(height: UIScreen.main.bounds.height - 150)
                    .padding(.bottom, 50)

                SeriesEpisodesView(viewModel: viewModel)
                    .environmentObject(focusGuide)

                ItemView.CastAndCrewHStack(people: viewModel.item.people?.filter(\.isDisplayed) ?? [])

                ItemView.SimilarItemsHStack(items: viewModel.similarItems)

                ItemView.AboutView(viewModel: viewModel)
            }
            .background {
                BlurView(style: .dark)
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(gradient: Gradient(stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white.opacity(0.7), location: 0.4),
                                .init(color: .white.opacity(0), location: 1),
                            ]), startPoint: .bottom, endPoint: .top)
                                .frame(height: UIScreen.main.bounds.height - 150)

                            Color.white
                        }
                    }
            }
        }
    }
}
