//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import JellyfinAPI

struct PortraitItemElement: View {
    @Environment(\.isFocused) var envFocused: Bool
    @State var focused: Bool = false
    @State var backgroundURL: URL?

    var item: BaseItemDto

    var body: some View {
        VStack {
            ImageView(src: item.type == "Episode" ? item.getSeriesPrimaryImage(maxWidth: 200) : item.getPrimaryImage(maxWidth: 200), bh: item.type == "Episode" ? item.getSeriesPrimaryImageBlurHash() : item.getPrimaryImageBlurHash())
                .frame(width: 200, height: 300)
                .cornerRadius(10)
                .shadow(radius: focused ? 10.0 : 0)
                .shadow(radius: focused ? 10.0 : 0)
                .overlay(
                    ZStack {
                        if item.userData?.isFavorite ?? false {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.white)
                                .opacity(0.6)
                            Image(systemName: "heart.fill")
                                .foregroundColor(Color(.systemRed))
                                .font(.system(size: 10))
                        }
                    }
                    .padding(2)
                    .opacity(1), alignment: .bottomLeading)
                .overlay(
                    ZStack {
                        if item.userData?.played ?? false {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.white)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(.systemBlue))
                        } else {
                            if item.userData?.unplayedItemCount != nil {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(Color(.systemBlue))
                                Text(String(item.userData!.unplayedItemCount ?? 0))
                                    .foregroundColor(.white)
                                    .font(.caption2)
                            }
                        }
                    }.padding(2)
                    .opacity(1), alignment: .topTrailing).opacity(1)
            Text(item.title)
              .frame(width: 200, height: 30, alignment: .center)
        }
        .onChange(of: envFocused) { envFocus in
            withAnimation(.linear(duration: 0.15)) {
                self.focused = envFocus
            }

            if envFocus == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // your code here
                    if focused == true {
                        backgroundURL = item.getBackdropImage(maxWidth: 1080)
                        BackgroundManager.current.setBackground(to: backgroundURL!, hash: item.getBackdropImageBlurHash())
                    }
                }
            }
        }
        .scaleEffect(focused ? 1.1 : 1)
    }
}
