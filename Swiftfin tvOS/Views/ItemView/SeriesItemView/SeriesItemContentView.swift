//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SeriesItemView {
    
    struct ContentView: View {
        
        @ObservedObject
        var viewModel: SeriesItemViewModel
        
        var body: some View {
            HStack {
                VStack {
                    SeriesEpisodeView(viewModel: viewModel)
                    
                    ItemView.PlayButton(viewModel: viewModel)
                }
                
                Spacer()
            }
        }
    }
}

struct PlainTextButton<Content: View>: View {
    
    var action: () -> Void
    var text: String
//    var content: () -> Content
    
    var body: some View {
        Text(text)
            .onSubmit {
                action()
            }
    }
}
