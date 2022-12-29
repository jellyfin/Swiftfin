//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import JellyfinAPI

struct HomeItemRow: View {
    @EnvironmentObject private var router: HomeCoordinator.Router
    @Environment(\.safeAreaInsets) private var edgeInsets: EdgeInsets
    
    public let items: [BaseItemDto]
    public let size: Columns
    public let focusPrefix: String
    public let focusedImage: FocusState<String?>.Binding
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 40) {
                    ForEach(items, id: \.id) { item in
                        let focusName = "\(focusPrefix)::\(item.id!)"
                        
                        ImageView(item.landscapePosterImageSources(maxWidth: size.rawValue))
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .cornerRadius(7.5)
                            .frame(width: size.rawValue, height: (size.rawValue / (16 / 9)))
                        
                            .focusable()
                            .focused(focusedImage, equals: focusName)
                            .scaleEffect(focusedImage.wrappedValue == focusName ? 1.11 : 1, anchor: size == .five ? .bottom : .center)
                            .animation(.easeInOut(duration: 0.25), value: focusedImage.wrappedValue == focusName)
                            .overlay {
                                if let progress = item.userData?.playedPercentage, progress != 0 {
                                    VStack {
                                        Spacer()
                                        ProgressBar(progress: progress / 100)
                                            .frame(height: 5)
                                    }
                                    .padding(10)
                                }
                            }
                            .onTapGesture {
                                router.route(to: \.item, item)
                            }
                    }
                }
                .frame(height: (size.rawValue / (16 / 9)) * (size == .four ? 1.11 : 1.22))
                .padding(.leading, edgeInsets.leading)
                .padding(.trailing, edgeInsets.trailing)
            }
        }
    }
    
    public enum Columns: CGFloat {
        case four = 410
        case five = 320
    }
}
