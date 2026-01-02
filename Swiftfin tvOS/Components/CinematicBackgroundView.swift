//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct CinematicBackgroundView: View {

    @ObservedObject
    var viewModel: Proxy

    @StateObject
    private var proxy: RotateContentView.Proxy = .init()

    var initialItem: (any Poster)?

    var body: some View {
        RotateContentView(proxy: proxy)
            .onChange(of: viewModel.currentItem) { _, newItem in
                proxy.update {
                    ImageView(newItem?.cinematicImageSources(maxWidth: nil) ?? [])
                        .placeholder { _ in
                            Color.clear
                        }
                        .failure {
                            Color.clear
                        }
                        .aspectRatio(contentMode: .fill)
                }
            }
    }

    class Proxy: ObservableObject {

        @Published
        var currentItem: AnyPoster?

        private var cancellables = Set<AnyCancellable>()
        private var currentItemSubject = CurrentValueSubject<AnyPoster?, Never>(nil)

        init() {
            currentItemSubject
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .removeDuplicates()
                .sink { newItem in
                    self.currentItem = newItem
                }
                .store(in: &cancellables)
        }

        func select(item: some Poster) {
            currentItemSubject.send(AnyPoster(item))
        }
    }
}
