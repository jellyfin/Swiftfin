//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ContentGroupParentOption: OptionSet {

    let rawValue: Int

    static let ignoreTopSafeArea = Self(rawValue: 1 << 0)
    static let useOffsetNavigationBar = Self(rawValue: 1 << 1)
}

struct ContentGroupCustomizationKey: PreferenceKey {
    static var defaultValue: ContentGroupParentOption = []

    static func reduce(
        value: inout ContentGroupParentOption,
        nextValue: () -> ContentGroupParentOption
    ) {
        value.formUnion(nextValue())
    }
}

struct LargePosterGroup: ContentGroup {

    let id = "item-view-header"
    let viewModel: Empty = .init()

    func body(with viewModel: Empty) -> some View {
        EmptyView()
    }
}

struct LargePosterHStack<
    Element: Poster,
    Data: Collection
>: View where Data.Element == Element, Data.Index == Int {

    @Environment(\.frameForParentView)
    private var frameForParentView

    @FocusState
    private var isSectionFocused

    @FocusedValue(\.focusedPoster)
    private var focusedPoster

    let elements: Data

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear

            PosterHStack(
                elements: elements,
                type: .landscape
            ) { _, _ in
                print("Focused Poster: \(String(describing: focusedPoster))")
            } header: {
                EmptyView()
            }
            .frame(height: 400, alignment: .bottomLeading)
            .debugBackground(Color.blue.opacity(0.5))
        }
        .ifLet(frameForParentView[.scrollView]) { view, frame in
            if frame.frame.height > 0 {
                view.frame(height: frame.frame.height)
                    .onAppear {
                        print("Setting height to \(frame.frame.height)")
                    }
            } else {
                view.aspectRatio(1.77, contentMode: .fit)
            }
        } transformElse: { view in
            view.aspectRatio(1.77, contentMode: .fit)
        }
        .debugBackground()
        .preference(
            key: ContentGroupCustomizationKey.self,
            value: [.ignoreTopSafeArea]
        )
    }
}
