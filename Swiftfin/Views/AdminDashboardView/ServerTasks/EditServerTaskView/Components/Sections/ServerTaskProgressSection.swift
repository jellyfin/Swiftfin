//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension EditServerTaskView {

    struct ProgressSection: View {

        @ObservedObject
        var observer: ServerTaskObserver

        var body: some View {
            if observer.task.state == .running || observer.task.state == .cancelling {
                Section(L10n.progress) {
                    if let status = observer.task.state {
                        TextPairView(
                            leading: L10n.status,
                            trailing: status.displayTitle
                        )
                    }

                    if let currentProgressPercentage = observer.task.currentProgressPercentage {
                        TextPairView(
                            L10n.progress,
                            value: Text("\(currentProgressPercentage / 100, format: .percent.precision(.fractionLength(1)))")
                        )
                        .monospacedDigit()
                    }

                    Button {
                        observer.send(.stop)
                    } label: {
                        HStack {
                            Text(L10n.stop)

                            Spacer()

                            Image(systemName: "stop.fill")
                        }
                    }
                    .foregroundStyle(.red)
                }
            } else {
                Button(L10n.run) {
                    observer.send(.start)
                }
            }
        }
    }
}
