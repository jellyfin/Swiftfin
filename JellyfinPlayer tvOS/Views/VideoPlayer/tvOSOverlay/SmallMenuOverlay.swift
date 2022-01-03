//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import JellyfinAPI
import SwiftUI

struct SmallMediaStreamSelectionView: View {
    
    @Binding var selectedItem: MediaStream?
    private let title: String
    private var items: [MediaStream]
    private var selectedAction: (MediaStream) -> Void
    
//    init(items: [MediaStream], selectedItem: MediaStream?, selectedAction: @escaping (MediaStream) -> Void) {
//        self.items = items
//        self.selectedItem = selectedItem
//        self.selectedAction = selectedAction
//    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
                .frame(height: 150)
            
            VStack {
                
                Spacer()
                
                HStack {
                    Text(title)
                        .font(.title3)
                    Spacer()
                }
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(items, id: \.self) { item in
                            Button {
                                self.selectedAction(item)
                            } label: {
                                if item == selectedItem {
                                    Label(item.displayTitle ?? "No Title", systemImage: "checkmark")
                                } else {
                                    Text(item.displayTitle ?? "No Title")
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 100)
            }
        }
    }
}
