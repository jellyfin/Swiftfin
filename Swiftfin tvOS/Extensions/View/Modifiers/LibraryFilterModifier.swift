//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LibraryFilterModifier<Filters: View, Letters: View>: ViewModifier {

    @Default(.Customization.Library.letterPickerEnabled)
    private var letterPickerEnabled
    @Default(.Customization.Library.letterPickerOrientation)
    private var letterPickerOrientation

    let filters: () -> Filters
    let letters: () -> Letters

    @State
    private var safeArea: EdgeInsets = .zero

    private let expandedWidth: CGFloat = 200

    @State
    private var isExpanded: Bool = false

    private var filtersAlignment: Alignment {
        letterPickerOrientation == .leading ? .trailing : .leading
    }

    private var filtersEdge: Edge.Set {
        letterPickerOrientation == .leading ? .trailing : .leading
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .frame(maxWidth: .infinity)
                .padding(.leading, expandedWidth + 10)
                .padding(.trailing, expandedWidth + 10)

            filters()
                .ignoresSafeArea(edges: filtersEdge)
                .frame(width: expandedWidth + 10)
                .position(
                    x: filtersAlignment == .leading ? (expandedWidth + 10) / 2 : UIScreen.main.bounds.width - (expandedWidth + 10) / 2,
                    y: UIScreen.main.bounds.height / 2
                )
                .padding(.bottom, safeArea.bottom)
                .padding(.top, safeArea.top)

            if letterPickerEnabled {
                letters()
                    .ignoresSafeArea(edges: letterPickerOrientation.edge)
                    .frame(width: expandedWidth + 10, alignment: .center)
                    .position(
                        x: letterPickerOrientation.alignment == .leading ? (expandedWidth + 10) / 2 : UIScreen.main.bounds
                            .width - (expandedWidth + 10) / 2,
                        y: UIScreen.main.bounds.height / 2
                    )
                    .padding(.bottom, safeArea.bottom)
                    .padding(.top, safeArea.top)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
