//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ScheduledTasksView {
    struct ServerTaskButton: View {
        var label: String
        var icon: String
        var warningMessage: String
        var isPresented: Binding<Bool>
        var action: () -> Void

        @ViewBuilder
        var body: some View {
            Button(role: .destructive) {
                isPresented.wrappedValue = true
            } label: {
                HStack {
                    Text(label)
                    Spacer()
                    Image(systemName: icon)
                }
            }
            .confirmationDialog(
                warningMessage,
                isPresented: isPresented,
                titleVisibility: .visible
            ) {
                Button(label, role: .destructive, action: action)
            }
        }
    }
}
