//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension UserListView {

    struct AddUserButton: View {

        let action: () -> Void

        var body: some View {
            VStack(alignment: .center) {
                Button {
                    action()
                } label: {
                    SystemImageContentView(systemName: "plus")
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(.circle)
                }

                Text("Add User")
                    .fontWeight(.semibold)
            }
        }
    }
}
