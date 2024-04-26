//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension UserListView {

    struct AddUserListRow: View {

        @Environment(\.isEnabled)
        private var isEnabled

        var onSelect: () -> Void

        var body: some View {
            Button {
                onSelect()
            } label: {
                HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

                    SystemImageContentView(systemName: "plus")
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(.circle)
                        .frame(width: 80)
                        .padding(.vertical, 8)

                    HStack {

                        Text("Add User")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(isEnabled ? .primary : .secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
    }
}
