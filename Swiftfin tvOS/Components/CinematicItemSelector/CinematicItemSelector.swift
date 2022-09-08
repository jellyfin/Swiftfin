//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI
import JellyfinAPI

struct CinematicItemSelector: View {
    
    @ObservedObject
    private var viewModel: CinematicItemSelectorViewModel = .init()
    
    let items: [BaseItemDto]
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            if let currentItem = viewModel.currentItem {
                ImageView(currentItem.landscapePosterImageSources(maxWidth: UIScreen.main.bounds.width))
                    .ignoresSafeArea()
                    .id(currentItem.hashValue)
            } else {
                Color.secondarySystemFill
            }
            
            PosterHStack(type: .landscape, items: items)
                .onSelect { item in
                    print("here")
                }
                .onFocus { item in
                    viewModel.select(item: item)
                }
                .content { _ in
                    EmptyView()
                }
        }
        .frame(height: UIScreen.main.bounds.height - 100)
        .frame(maxWidth: .infinity)
        .animation(.linear, value: viewModel.currentItem)
    }
    
    class CinematicItemSelectorViewModel: ViewModel {
        
        @Published
        var currentItem: BaseItemDto?
        
        private var currentItemSubject = CurrentValueSubject<BaseItemDto?, Never>(nil)
        
        override init() {
            super.init()
            currentItemSubject
                .debounce(for: 0.5, scheduler: DispatchQueue.main)
                .sink { newItem in
                    self.currentItem = newItem
                }
                .store(in: &cancellables)
        }
        
        func select(item: BaseItemDto) {
            currentItemSubject.send(item)
        }
    }
}
