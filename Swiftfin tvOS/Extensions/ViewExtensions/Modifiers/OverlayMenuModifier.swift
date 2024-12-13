//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OverlayMenuModifier<Contents: View>: ViewModifier {

    @Binding
    var isPresented: Bool
    let title: String?
    let subtitle: String?
    let contents: Contents
    let dismissActions: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                menuView
            }
    }

    @ViewBuilder
    private var menuView: some View {
        VStack {
            if let title = title {
                Text(title)
                    .font(.title)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.horizontal)
            }
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.horizontal)
            }
            ScrollView {
                contents
                    .padding()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Material.regular)
        }
        .frame(
            maxWidth: UIScreen.main.bounds.width / 2,
            maxHeight: UIScreen.main.bounds.height / 1.5
        )
        .fixedSize(horizontal: false, vertical: true)
        .edgesIgnoringSafeArea(.top)
        .edgesIgnoringSafeArea(.bottom)
    }
}
