//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LetterPickerBarModifier: ViewModifier {

    @Default(.Customization.Library.letterPickerOrientation)
    private var letterPickerOrientation

    @Environment(\.filterBarEdge)
    private var filterBarEdge

    let viewModel: FilterViewModel?

    private func ignoredSafeAreaEdges(letterPickerEdge: HorizontalEdge?) -> Edge.Set {
        var edges: Edge.Set = []

        if letterPickerEdge != .leading, filterBarEdge != .leading {
            edges.insert(.leading)
        }

        if letterPickerEdge != .trailing, filterBarEdge != .trailing {
            edges.insert(.trailing)
        }

        return edges
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if let edge = letterPickerOrientation.edge,
           let viewModel
        {
            content
                .focusSection()
                .ignoresSafeArea(.all, edges: ignoredSafeAreaEdges(letterPickerEdge: edge))
                .safeAreaInset(edge: edge, alignment: .center, spacing: 0) {
                    LetterPickerBar(viewModel: viewModel)
                }
                .ignoresSafeArea(.all, edges: UIDevice.isTV ? edge.asEdgeSet : [])
                .overlayPreferenceValue(LetterPickerActiveLetterKey.self) { letter in
                    ZStack {
                        if let letter {
                            LetterPickerBar.LetterPickerCallout(letter: letter)
                                .font(.system(size: UIDevice.isTV ? 128 : 64, design: .rounded).weight(.bold))
                        }
                    }
                }
        } else {
            content
                .ignoresSafeArea(.all, edges: ignoredSafeAreaEdges(letterPickerEdge: nil))
        }
    }
}
