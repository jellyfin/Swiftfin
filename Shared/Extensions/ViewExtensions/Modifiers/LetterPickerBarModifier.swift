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

    @ViewBuilder
    func body(content: Content) -> some View {
        if let letterPickerEdge = letterPickerOrientation.edge,
           let viewModel
        {
            content
                .focusSection()
                .ignoresSafeArea(
                    .all,
                    edges: Edge.Set.horizontal
                        .subtracting(filterBarEdge?.asEdgeSet ?? [])
                        .subtracting(letterPickerEdge.asEdgeSet)
                )
                .safeAreaInset(
                    edge: letterPickerEdge,
                    alignment: .center, spacing: 0
                ) {
                    LetterPickerBar(viewModel: viewModel)
                }
                .ignoresSafeArea(.all, edges: UIDevice.isTV ? letterPickerEdge.asEdgeSet : [])
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
                .ignoresSafeArea(
                    .all,
                    edges: Edge.Set.horizontal
                        .subtracting(filterBarEdge?.asEdgeSet ?? [])
                )
        }
    }
}
