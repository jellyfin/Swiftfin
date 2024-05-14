//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FullScreenMenu<Content: View>: View {

    private let content: () -> Content
    private let title: String

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.5)

            HStack {
                Spacer()

                VStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)

                    ScrollView {
                        VStack {
                            content()
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(width: 580)
                }
                .padding(.top, 20)
                .background(Material.regular, in: RoundedRectangle(cornerRadius: 30))
                .frame(width: 620)
                .padding(100)
                .shadow(radius: 50)
            }
        }
        .ignoresSafeArea()
    }
}
