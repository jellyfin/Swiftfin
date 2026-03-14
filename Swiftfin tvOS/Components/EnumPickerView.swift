//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EnumPickerView<EnumType: CaseIterable & Displayable & Hashable & RawRepresentable>: View {

    @Binding
    private var selection: EnumType

    private var descriptionView: () -> any View
    private var title: String?

    var body: some View {
        SplitFormWindowView()
            .descriptionView(descriptionView)
            .contentView {
                Section {
                    ForEach(EnumType.allCases.asArray, id: \.hashValue) { item in
                        Button {
                            selection = item
                        } label: {
                            HStack {
                                Text(item.displayTitle)

                                Spacer()

                                if selection == item {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }
                        }
                    }
                }
            }
    }
}

extension EnumPickerView {

    init(
        title: String? = nil,
        selection: Binding<EnumType>
    ) {
        self.init(
            selection: selection,
            descriptionView: { EmptyView() },
            title: title
        )
    }

    func descriptionView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.descriptionView, with: content)
    }
}
