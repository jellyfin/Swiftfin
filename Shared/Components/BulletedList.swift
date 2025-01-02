//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BulletedList<Content: View>: View {

    private var content: () -> Content
    private var bullet: (Int) -> any View

    var body: some View {
        _VariadicView.Tree(BulletedListLayout(bullet: bullet)) {
            content()
        }
    }
}

extension BulletedList {

    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.init(
            content: content,
            bullet: { _ in
                ZStack {
                    Text(" ")

                    Circle()
                        .frame(width: 8)
                        .padding(.trailing, 5)
                }
            }
        )
    }

    func bullet(@ViewBuilder _ content: @escaping (Int) -> any View) -> Self {
        copy(modifying: \.bullet, with: content)
    }
}

extension BulletedList {

    struct BulletedListLayout: _VariadicView_UnaryViewRoot {

        var bullet: (Int) -> any View

        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(zip(children.indices, children)), id: \.0) { child in
                    BulletedListItem(
                        bullet: AnyView(bullet(child.0)),
                        child: child.1
                    )
                }
            }
        }
    }

    struct BulletedListItem<BulletContent: View, Bullet: View>: View {

        @State
        private var bulletSize: CGSize = .zero
        @State
        private var childSize: CGSize = .zero

        let bullet: Bullet
        let child: BulletContent

        private var _bullet: some View {
            bullet
                .trackingSize($bulletSize)
        }

        // TODO: this can cause clipping issues with text since
        //       with .offset, find fix
        var body: some View {
            ZStack {
                child
                    .trackingSize($childSize)
                    .overlay(alignment: .topLeading) {
                        _bullet
                            .offset(x: -bulletSize.width)
                    }
            }
        }
    }
}
