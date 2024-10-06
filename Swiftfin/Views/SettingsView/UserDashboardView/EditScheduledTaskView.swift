//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: last run details
//       - result, show error if available
// TODO: observe running status
//       - stop
//       - run
//       - progress
// TODO: triggers

struct EditScheduledTaskView: View {

    @CurrentDate
    private var currentDate: Date

    @ObservedObject
    var observer: ServerTaskObserver

    var body: some View {
        List {

            ListTitleSection(
                observer.task.name ?? L10n.unknown,
                description: observer.task.description
            )

            if let category = observer.task.category {
                TextPairView(
                    leading: L10n.category,
                    trailing: category
                )
            }

            if let lastEndTime = observer.task.lastExecutionResult?.endTimeUtc {
                TextPairView(
                    L10n.lastRun,
                    value: Text("\(lastEndTime, format: .relative(presentation: .numeric, unitsStyle: .narrow))")
                )
                .id(currentDate)
                .monospacedDigit()

                if let lastStartTime = observer.task.lastExecutionResult?.startTimeUtc {
                    TextPairView(
                        L10n.runtime,
                        value: Text(
                            "\(lastStartTime ..< lastEndTime, format: .components(style: .narrow))"
                        )
                    )
                }
            }
        }
        .navigationTitle(L10n.task)
    }
}

// TODO: remove after view done
#Preview {
    NavigationView {
        EditScheduledTaskView(
            observer: .init(
                task: TaskInfo(
                    category: "test",
                    currentProgressPercentage: nil,
                    description: "A test task",
                    id: "123",
                    isHidden: false,
                    key: "123",
                    lastExecutionResult: TaskResult(
                        endTimeUtc: Date(timeIntervalSinceNow: -10),
                        errorMessage: nil,
                        id: nil,
                        key: nil,
                        longErrorMessage: nil,
                        name: nil,
                        startTimeUtc: Date(timeIntervalSinceNow: -30),
                        status: .completed
                    ),
                    name: "Test",
                    state: .running,
                    triggers: nil
                )
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}
