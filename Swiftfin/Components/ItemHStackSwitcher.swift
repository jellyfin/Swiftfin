//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

protocol ItemHStackSwitcherManager: ObservableObject {
    associatedtype Section: Hashable, Displayable
    associatedtype Item: Poster

    var selection: Section? { get }
    var sections: [Section: [Item]] { get set }
    var sectionMenuSort: (Section, Section) -> Bool { get }

    func select(section: Section)
}

class SpecialFeaturesViewModel: ViewModel, ItemHStackSwitcherManager {

    @Published
    var selection: SpecialFeatureType?
    @Published
    var sections: [SpecialFeatureType: [BaseItemDto]]
    var sectionMenuSort: (SpecialFeatureType, SpecialFeatureType) -> Bool

    init(sections: [SpecialFeatureType: [BaseItemDto]]) {
        let comparator: (SpecialFeatureType, SpecialFeatureType) -> Bool = { i, j in i.rawValue < j.rawValue }
        self.selection = Array(sections.keys).sorted(by: comparator).first!
        self.sections = sections
        self.sectionMenuSort = comparator
    }

    func select(section: SpecialFeatureType) {
        self.selection = section
    }
}

struct ItemHStackSwitcher<Manager: ItemHStackSwitcherManager, Content: View, ImageOverlay: View, ContextMenu: View>: View {

    @ObservedObject
    private var manager: Manager

    private let type: PosterType
    private var itemScale: CGFloat
    private let singleImage: Bool
    private var content: (Manager.Item) -> Content
    private var imageOverlay: (Manager.Item) -> ImageOverlay
    private var contextMenu: (Manager.Item) -> ContextMenu
    private var onSelect: (Manager.Item) -> Void

    var body: some View {
        if let selection = manager.selection {
            PosterHStack(
                type: type,
                items: manager.sections[selection] ?? [],
                singleImage: singleImage
            )
            .scaleItems(itemScale)
            .header {
                Menu {
                    ForEach(manager.sections.keys.sorted(by: { manager.sectionMenuSort($0, $1) }), id: \.displayName) { section in
                        Button {
                            manager.select(section: section)
                        } label: {
                            if section == manager.selection {
                                Label(section.displayName, systemImage: "checkmark")
                            } else {
                                Text(section.displayName)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Group {
                            Text(selection.displayName)
                                .fixedSize()
                            Image(systemName: "chevron.down")
                        }
                        .font(.title3.weight(.semibold))
                    }
                }
            }
            .content(content)
            .imageOverlay(imageOverlay)
            .contextMenu(contextMenu)
            .onSelect { item in
                onSelect(item)
            }
        } else {
            PosterHStack(
                type: type,
                items: [BaseItemDto.noResults]
            )
        }
    }
}

extension ItemHStackSwitcher where Content == PosterButtonDefaultContentView<Manager.Item>,
    ImageOverlay == EmptyView,
    ContextMenu == EmptyView
{

    init(
        type: PosterType,
        manager: Manager,
        singleImage: Bool = false
    ) {
        self.init(
            manager: manager,
            type: type,
            itemScale: 1,
            singleImage: singleImage,
            content: { PosterButtonDefaultContentView(item: $0) },
            imageOverlay: { _ in EmptyView() },
            contextMenu: { _ in EmptyView() },
            onSelect: { _ in }
        )
    }
}

extension ItemHStackSwitcher {
    
    func scaleItems(_ scale: CGFloat) -> Self {
        copy(modifying: \.itemScale, with: scale)
    }

    func content<C: View>(@ViewBuilder _ content: @escaping (Manager.Item) -> C)
    -> ItemHStackSwitcher<Manager, C, ImageOverlay, ContextMenu> {
        .init(
            manager: manager,
            type: type,
            itemScale: itemScale,
            singleImage: singleImage,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            onSelect: onSelect
        )
    }
    
    func imageOverlay<O: View>(@ViewBuilder _ imageOverlay: @escaping (Manager.Item) -> O)
    -> ItemHStackSwitcher<Manager, Content, O, ContextMenu> {
        .init(
            manager: manager,
            type: type,
            itemScale: itemScale,
            singleImage: singleImage,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            onSelect: onSelect
        )
    }
    
    func contextMenu<C: View>(@ViewBuilder _ contextMenu: @escaping (Manager.Item) -> C)
    -> ItemHStackSwitcher<Manager, Content, ImageOverlay, C> {
        .init(
            manager: manager,
            type: type,
            itemScale: itemScale,
            singleImage: singleImage,
            content: content,
            imageOverlay: imageOverlay,
            contextMenu: contextMenu,
            onSelect: onSelect
        )
    }

    func onSelect(_ action: @escaping (Manager.Item) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
