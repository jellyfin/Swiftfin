//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: remove and replace with icon of item type instead
struct InitialFailureView: View {

    let initials: String

    init(_ initials: String) {
        self.initials = initials
    }

    var body: some View {
        ZStack {
            Color.secondarySystemFill
                .opacity(0.5)

            Text(initials)
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
    }
}

struct TypeSystemNameView<Item: Poster>: View {

    @State
    private var contentSize: CGSize = .zero

    let item: Item

    var body: some View {
        ZStack {
            Color.secondarySystemFill
                .opacity(0.5)

            if let typeSystemImage = item.typeSystemImage {
                Image(systemName: typeSystemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                    .frame(width: contentSize.width / 3.5, height: contentSize.height / 3)
            }
        }
        .onSizeChanged { newSize in
            contentSize = newSize
        }
    }
}
