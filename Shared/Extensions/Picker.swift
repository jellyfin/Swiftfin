//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

func Picker<ItemType>(
    _ title: String,
    selection: Binding<ItemType>
) -> some View where ItemType: CaseIterable & Displayable & Hashable,
    ItemType.AllCases: RandomAccessCollection
{
    #if os(tvOS)
    ListRowMenu(title, selection: selection)
    #else
    SwiftUI.Picker(title, selection: selection) {
        ForEach(Array(ItemType.allCases), id: \.self) { option in
            Text(option.displayTitle).tag(option)
        }
    }
    #endif
}
