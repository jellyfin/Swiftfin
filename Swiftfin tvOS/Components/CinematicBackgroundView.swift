//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct CinematicBackgroundView<Item: Poster>: View {

    @ObservedObject
    var viewModel: ViewModel

    @StateObject
    private var proxy: RotateContentView.Proxy = .init()

    var initialItem: Item?

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

    class ViewModel: ObservableObject {

        @Published
        var currentItem: Item?

        private var cancellables = Set<AnyCancellable>()
        private var currentItemSubject = CurrentValueSubject<Item?, Never>(nil)

        init() {
            currentItemSubject
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .removeDuplicates()
                .sink { newItem in
                    self.currentItem = newItem
                }
                .store(in: &cancellables)
        }

        func select(item: Item) {
            currentItemSubject.send(item)
        }
    }
}
