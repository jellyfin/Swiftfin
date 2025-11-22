//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

// TODO: make new protocol for cinematic view image provider
// TODO: better name

struct CinematicItemSelector<
    Element: Poster,
    Data: Collection
>: View where Data.Element == Element, Data.Index == Int {

    @FocusState
    private var isSectionFocused

    @FocusedValue(\.focusedPoster)
    private var focusedPoster

    @StateObject
    private var viewModel: CinematicBackgroundView.Proxy = .init()

    private let elements: Data
    private var topContent: (Element) -> any View
    private var itemContent: (Element) -> any View
    private var trailingContent: () -> any View
    private var onSelect: (Element) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            if let focusedPoster, let focusedItem = focusedPoster._poster as? Element {
                topContent(focusedItem)
                    .eraseToAnyView()
                    .id(focusedItem.hashValue)
                    .transition(.opacity)
            }

            PosterHStack(
                elements: elements,
                type: .landscape
            ) { element, _ in
                onSelect(element)
            } header: {
                EmptyView()
            }
            .frame(height: 400)

            // TODO: fix intrinsic content sizing without frame
//            PosterHStack(
//                type: .landscape,
//                items: items,
//                action: onSelect,
//                label: itemContent
//            )
//            .frame(height: 400)
        }
        .frame(height: UIScreen.main.bounds.height - 75, alignment: .bottomLeading)
        .frame(maxWidth: .infinity)
        .background(alignment: .top) {
            CinematicBackgroundView(
                viewModel: viewModel,
                initialItem: elements.first
            )
            .overlay {
                Color.black
                    .maskLinearGradient {
                        (location: 0.5, opacity: 0)
                        (location: 0.6, opacity: 0.4)
                        (location: 1, opacity: 1)
                    }
            }
            .frame(height: UIScreen.main.bounds.height)
            .maskLinearGradient {
                (location: 0.9, opacity: 1)
                (location: 1, opacity: 0)
            }
        }
        .onChange(of: focusedPoster) {
            guard let focusedPoster, isSectionFocused else { return }
            viewModel.select(item: focusedPoster)
        }
        .focusSection()
        .focused($isSectionFocused)
    }
}

extension CinematicItemSelector {

    init(items: Data) {
        self.init(
            elements: items,
            topContent: { _ in EmptyView() },
            itemContent: { _ in EmptyView() },
            trailingContent: { EmptyView() },
            onSelect: { _ in }
        )
    }
}

extension CinematicItemSelector {

    func topContent(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.topContent, with: content)
    }

    func content(@ViewBuilder _ content: @escaping (Element) -> any View) -> Self {
        copy(modifying: \.itemContent, with: content)
    }

    func trailingContent<T: View>(@ViewBuilder _ content: @escaping () -> T) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }

    func onSelect(_ action: @escaping (Element) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
