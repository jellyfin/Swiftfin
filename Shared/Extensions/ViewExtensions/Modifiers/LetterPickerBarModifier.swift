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

    @Default(.accentColor)
    private var accentColor
    @Default(.Customization.Library.letterPickerOrientation)
    private var letterPickerOrientation

    let viewModel: FilterViewModel?

    @ViewBuilder
    func body(content: Content) -> some View {
        if letterPickerOrientation != .disabled,
           let edge = letterPickerOrientation.edge,
           let viewModel
        {
            content
                .ignoresSafeArea(.all, edges: edge == .leading ? .trailing : .leading)
                .safeAreaInset(edge: edge, alignment: .center, spacing: 0) {
                    LetterPickerBar(viewModel: viewModel)
                        .foregroundStyle(accentColor.overlayColor, accentColor, Color.primary)
                        .if(!UIDevice.isTV) { view in
                            view
                                .padding(.vertical, EdgeInsets.edgePadding / 2)
                                .padding(edge == .leading ? .leading : .trailing, EdgeInsets.edgePadding / 2)
                        }
                        .if(UIDevice.isTV) { view in
                            view
                                .focusSection()
                        }
                }
        } else {
            content
                .ignoresSafeArea(.all, edges: .horizontal)
        }
    }
}
