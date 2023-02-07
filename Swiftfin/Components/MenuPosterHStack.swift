//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct MenuPosterHStack<Model: MenuPosterHStackModel>: View {

    @ObservedObject
    private var manager: Model

    private let type: PosterType
    private var itemScale: CGFloat
    private let singleImage: Bool
    private var content: (PosterButtonType<Model.Item>) -> any View
    private var imageOverlay: (PosterButtonType<Model.Item>) -> any View
    private var contextMenu: (PosterButtonType<Model.Item>) -> any View
    private var onSelect: (Model.Item) -> Void

    @ViewBuilder
    private var selectorMenu: some View {
        Menu {
            ForEach(manager.menuSections.keys.sorted(by: { manager.menuSectionSort($0, $1) }), id: \.displayTitle) { section in
                Button {
                    manager.select(section: section)
                } label: {
                    if section == manager.menuSelection {
                        Label(section.displayTitle, systemImage: "checkmark")
                    } else {
                        Text(section.displayTitle)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Group {
                    Text(manager.menuSelection?.displayTitle ?? L10n.unknown)
                        .fixedSize()
                    Image(systemName: "chevron.down")
                }
                .font(.title3.weight(.semibold))
            }
        }
        .padding(.bottom)
        .fixedSize()
    }

    private var items: [PosterButtonType<Model.Item>] {
        guard let selection = manager.menuSelection,
              let items = manager.menuSections[selection] else { return [.noResult] }
        return items
    }

    var body: some View {
        PosterHStack(
            type: type,
            items: items,
            singleImage: singleImage
        )
        .header {
            selectorMenu
        }
        .scaleItems(itemScale)
        .content(content)
        .imageOverlay(imageOverlay)
        .contextMenu(contextMenu)
        .onSelect { item in
            onSelect(item)
        }
    }
}

extension MenuPosterHStack {

    init(
        type: PosterType,
        manager: Model,
        singleImage: Bool = false
    ) {
        self.init(
            manager: manager,
            type: type,
            itemScale: 1,
            singleImage: singleImage,
            content: { _ in EmptyView() },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            onSelect: { _ in }
        )
    }
}

extension MenuPosterHStack {

    func scaleItems(_ scale: CGFloat) -> Self {
        copy(modifying: \.itemScale, with: scale)
    }

    func content(@ViewBuilder _ content: @escaping (PosterButtonType<Model.Item>) -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func imageOverlay(@ViewBuilder _ content: @escaping (PosterButtonType<Model.Item>) -> any View) -> Self {
        copy(modifying: \.imageOverlay, with: content)
    }

    func contextMenu(@ViewBuilder _ content: @escaping (PosterButtonType<Model.Item>) -> any View) -> Self {
        copy(modifying: \.contextMenu, with: content)
    }

    func onSelect(_ action: @escaping (Model.Item) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
