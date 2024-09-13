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
    struct ScheduledTaskButton: View {
        var taskID: String
        var taskName: String
        var progress: Double?
        var onSelect: () -> Void
        var onCancel: () -> Void

        @State
        private var isCancelling = false

        // MARK: Body

        @ViewBuilder
        var body: some View {
            Button(action: {
                isCancelling = false
                onSelect()
            }) {
                taskLabel
            }
        }

        // MARK: Task Label

        private var taskLabel: some View {
            HStack {
                Text(taskName.localizedCapitalized)
                    .foregroundColor(.primary)

                Spacer()

                if let progress = progress,
                   progress > 0 && progress < 100
                {
                    if isCancelling {
                        Text(L10n.cancel)
                            .foregroundColor(.red)

                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                    } else {
                        Text(
                            NumberFormatter.localizedString(
                                from: NSNumber(
                                    value: progress / 100
                                ),
                                number: .percent
                            )
                        )
                        .foregroundColor(.secondary)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.horizontal, 8)

                        Image(systemName: "x.circle")
                            .foregroundColor(.red)
                            .onTapGesture {
                                isCancelling = true
                                onCancel()
                            }
                    }
                } else {
                    Image(systemName: "play.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
