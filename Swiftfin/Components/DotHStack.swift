//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Check for if statements, look at ViewBuilder's buildIf

struct DotHStack: View {

    private let items: [AnyView]
    private let restItems: [AnyView]
    private let alignment: HorizontalAlignment

    var body: some View {
        HStack {
            items.first

            ForEach(0 ..< restItems.count, id: \.self) { i in

                Circle()
                    .frame(width: 2, height: 2)

                restItems[i]
            }
        }
    }
}

extension DotHStack {

    init<Data: RandomAccessCollection, Content: View>(
        _ data: Data,
        id: KeyPath<Data.Element, Data.Element> = \.self,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.alignment = alignment
        self.items = data.map { content($0[keyPath: id]).eraseToAnyView() }
        self.restItems = Array(items.dropFirst())
    }

    init<A: View>(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> A
    ) {
        self.alignment = alignment
        self.items = [content().eraseToAnyView()]
        self.restItems = Array(items.dropFirst())
    }

    init<A: View, B: View>(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> TupleView<(A, B)>
    ) {
        self.alignment = alignment
        let _content = content()

        self.items = [
            _content.value.0.eraseToAnyView(),
            _content.value.1.eraseToAnyView(),
        ]
        self.restItems = Array(items.dropFirst())
    }

    init<A: View, B: View, C: View>(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> TupleView<(A, B, C)>
    ) {
        self.alignment = alignment
        let _content = content()

        self.items = [
            _content.value.0.eraseToAnyView(),
            _content.value.1.eraseToAnyView(),
            _content.value.2.eraseToAnyView(),
        ]
        self.restItems = Array(items.dropFirst())
    }

    init<A: View, B: View, C: View, D: View>(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> TupleView<(A, B, C, D)>
    ) {
        self.alignment = alignment
        let _content = content()
        self.items = [
            _content.value.0.eraseToAnyView(),
            _content.value.1.eraseToAnyView(),
            _content.value.2.eraseToAnyView(),
            _content.value.3.eraseToAnyView(),
        ]
        self.restItems = Array(items.dropFirst())
    }

    init<A: View, B: View, C: View, D: View, E: View>(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> TupleView<(A, B, C, D, E)>
    ) {
        self.alignment = alignment
        let _content = content()
        self.items = [
            _content.value.0.eraseToAnyView(),
            _content.value.1.eraseToAnyView(),
            _content.value.2.eraseToAnyView(),
            _content.value.3.eraseToAnyView(),
            _content.value.4.eraseToAnyView(),
        ]
        self.restItems = Array(items.dropFirst())
    }

    init<A: View, B: View, C: View, D: View, E: View, F: View>(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> TupleView<(A, B, C, D, E, F)>
    ) {
        self.alignment = alignment
        let _content = content()
        self.items = [
            _content.value.0.eraseToAnyView(),
            _content.value.1.eraseToAnyView(),
            _content.value.2.eraseToAnyView(),
            _content.value.3.eraseToAnyView(),
            _content.value.4.eraseToAnyView(),
            _content.value.5.eraseToAnyView(),
        ]
        self.restItems = Array(items.dropFirst())
    }

    init<A: View, B: View, C: View, D: View, E: View, F: View, G: View>(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> TupleView<(A, B, C, D, E, F, G)>
    ) {
        self.alignment = alignment
        let _content = content()
        self.items = [
            _content.value.0.eraseToAnyView(),
            _content.value.1.eraseToAnyView(),
            _content.value.2.eraseToAnyView(),
            _content.value.3.eraseToAnyView(),
            _content.value.4.eraseToAnyView(),
            _content.value.5.eraseToAnyView(),
            _content.value.6.eraseToAnyView(),
        ]
        self.restItems = Array(items.dropFirst())
    }

    init<A: View, B: View, C: View, D: View, E: View, F: View, G: View, H: View>(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: ()
            -> TupleView<(A, B, C, D, E, F, G, H)>
    ) {
        self.alignment = alignment
        let _content = content()
        self.items = [
            _content.value.0.eraseToAnyView(),
            _content.value.1.eraseToAnyView(),
            _content.value.2.eraseToAnyView(),
            _content.value.3.eraseToAnyView(),
            _content.value.4.eraseToAnyView(),
            _content.value.5.eraseToAnyView(),
            _content.value.6.eraseToAnyView(),
            _content.value.7.eraseToAnyView(),
        ]
        self.restItems = Array(items.dropFirst())
    }

    init<A: View, B: View, C: View, D: View, E: View, F: View, G: View, H: View, I: View>(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: ()
            -> TupleView<(A, B, C, D, E, F, G, H, I)>
    ) {
        self.alignment = alignment
        let _content = content()
        self.items = [
            _content.value.0.eraseToAnyView(),
            _content.value.1.eraseToAnyView(),
            _content.value.2.eraseToAnyView(),
            _content.value.3.eraseToAnyView(),
            _content.value.4.eraseToAnyView(),
            _content.value.5.eraseToAnyView(),
            _content.value.6.eraseToAnyView(),
            _content.value.7.eraseToAnyView(),
            _content.value.8.eraseToAnyView(),
        ]
        self.restItems = Array(items.dropFirst())
    }

    init<
        A: View,
        B: View,
        C: View,
        D: View,
        E: View,
        F: View,
        G: View,
        H: View,
        I: View,
        J: View
    >(
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: ()
            -> TupleView<(
                A,
                B,
                C,
                D,
                E,
                F,
                G,
                H,
                I,
                J
            )>
    ) {
        self.alignment = alignment
        let _content = content()
        self.items = [
            _content.value.0.eraseToAnyView(),
            _content.value.1.eraseToAnyView(),
            _content.value.2.eraseToAnyView(),
            _content.value.3.eraseToAnyView(),
            _content.value.4.eraseToAnyView(),
            _content.value.5.eraseToAnyView(),
            _content.value.6.eraseToAnyView(),
            _content.value.7.eraseToAnyView(),
            _content.value.8.eraseToAnyView(),
            _content.value.9.eraseToAnyView(),
        ]
        self.restItems = Array(items.dropFirst())
    }
}
