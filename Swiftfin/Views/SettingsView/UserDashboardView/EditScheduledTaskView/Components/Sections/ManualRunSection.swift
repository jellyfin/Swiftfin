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

    struct ManualRunSection: View {

        @ObservedObject
        var observer: ServerTaskObserver

        var body: some View {
            Section("Actions") {
                if observer.task.state == .running || observer.task.state == .cancelling {
                    ChevronButton(L10n.stop)
                        .onSelect {
                            observer.send(.stop)
                        }
                } else {
                    ChevronButton(L10n.run)
                        .onSelect {
                            observer.send(.start)
                        }
                }
            }
        }
    }
}
