//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A `VStack` that displays subviews with a marker on the top leading edge.
///
/// In a marker view, ensure that views that are only used for layout are
/// tagged with `hidden` to avoid them being read by accessibility features.
struct MarkedList<Content: View, Marker: View>: View {

    private let content: Content
    private let marker: (Int) -> Marker
    private let spacing: CGFloat

    init(
        spacing: CGFloat,
        @ViewBuilder marker: @escaping (Int) -> Marker,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.marker = marker
        self.content = content()
        self.spacing = spacing
    }

    var body: some View {
        _VariadicView.Tree(
            MarkedListLayout(
                spacing: spacing,
                marker: marker
            )
        ) {
            content
        }
    }
}

extension MarkedList {

    struct MarkedListLayout: _VariadicView_UnaryViewRoot {

        let spacing: CGFloat
        let marker: (Int) -> Marker

        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(Array(zip(children.indices, children)), id: \.0) { child in
                    MarkedListEntry(
                        marker: marker(child.0),
                        content: child.1
                    )
                }
            }
        }
    }

    struct MarkedListEntry<EntryContent: View>: View {

        @State
        private var markerSize: CGSize = .zero
        @State
        private var childSize: CGSize = .zero

        let marker: Marker
        let content: EntryContent

        private var _bullet: some View {
            marker
                .trackingSize($markerSize)
        }

        // TODO: this can cause clipping issues with text since
        //       with .offset, find fix
        var body: some View {
            ZStack {
                content
                    .trackingSize($childSize)
                    .overlay(alignment: .topLeading) {
                        _bullet
                            .offset(x: -markerSize.width)
                    }
            }
        }
    }
}
