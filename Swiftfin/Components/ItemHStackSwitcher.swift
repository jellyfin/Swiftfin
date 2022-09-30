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
    
    var selection: Section { get }
    var sections: [Section: [BaseItemDto]] { get set }
    var sectionMenuSort: (Section, Section) -> Bool { get }
    
    func select(section: Section)
}

class SpecialFeaturesViewModel: ViewModel, ItemHStackSwitcherManager {
    
    @Published
    var selection: SpecialFeatureType
    @Published
    var sections: [SpecialFeatureType : [BaseItemDto]]
    var sectionMenuSort: (SpecialFeatureType, SpecialFeatureType) -> Bool
    
    init(sections: [SpecialFeatureType: [BaseItemDto]]) {
        let comparator: (SpecialFeatureType, SpecialFeatureType) -> Bool = { i, j in i.rawValue < j.rawValue}
        self.selection = Array(sections.keys).sorted(by: comparator).first!
        self.sections = sections
        self.sectionMenuSort = comparator
    }
    
    func select(section: SpecialFeatureType) {
        self.selection = section
    }
}

struct ItemHStackSwitcher<Manager: ItemHStackSwitcherManager>: View {
    
    @ObservedObject
    private var manager: Manager
    
    private let type: PosterType
    private var onSelect: (BaseItemDto) -> Void
    
    var body: some View {
        PosterHStack(
            type: type,
            items: manager.sections[manager.selection] ?? []
        )
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
                        Text(manager.selection.displayName)
                            .fixedSize()
                        Image(systemName: "chevron.down")
                    }
                    .font(.title3.weight(.semibold))
                }
            }
        }
        .onSelect { item in
            onSelect(item)
        }
    }
}

extension ItemHStackSwitcher {
    
    init(type: PosterType,
         manager: Manager) {
        self.type = type
        self.manager = manager
        self.onSelect = { _ in }
    }
    
    func onSelect(_ action: @escaping (BaseItemDto) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
