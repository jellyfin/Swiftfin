//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension EditScheduledTaskView {

    struct LastErrorSection: View {

        var lastExecutionResult: TaskResult

        var body: some View {
            Section(L10n.errorDetails) {
                if let errorMessage = lastExecutionResult.errorMessage {
                    Text(errorMessage)
                }
                if let longErrorMessage = lastExecutionResult.longErrorMessage {
                    Text(longErrorMessage)
                }
            }
        }
    }
}
