//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OfflineHomeView: View {
    
    @EnvironmentObject
    var offlineHomeRouter: OfflineHomeCoordinator.Router
    @ObservedObject
    var viewModel: OfflineHomeViewModel
    
    @ViewBuilder
    private var itemList: some View {
        ScrollView {
            VStack {
                ForEach(viewModel.offlineItems, id: \.self) { offlineItem in
                    
                    Button {
                        offlineHomeRouter.route(to: \.item, offlineItem)
                    } label: {
                        HStack {
                            if let backdropImageURL = offlineItem.backdropImageURL {
                                ImageView(src: backdropImageURL )
                                    .frame(width: 130, height: 100)
                                    .cornerRadius(5)
                            } else {
                                Color.gray
                                    .frame(width: 130, height: 100)
                                    .cornerRadius(5)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(offlineItem.item.title)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(UIColor.label))
                                
                                if offlineItem.item.itemType == .episode {
                                    Text(offlineItem.item.getEpisodeLocator() ?? "--")
                                        .font(.subheadline)
                                        .foregroundColor(Color(UIColor.secondaryLabel))
                                }
                                
                                Spacer()
                                
                                Text(offlineItem.storage)
                                    .font(.subheadline)
                                    .foregroundColor(Color(UIColor.secondaryLabel))
                            }
                            .padding(.vertical, 2)
                            
                            Spacer()
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if viewModel.offlineItems.isEmpty {
                Text("No items")
            } else {
                itemList
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    offlineHomeRouter.route(to: \.settings)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .accessibilityLabel(L10n.settings)
                }
            }
        }
        .navigationBarTitle("Offline")
    }
}
