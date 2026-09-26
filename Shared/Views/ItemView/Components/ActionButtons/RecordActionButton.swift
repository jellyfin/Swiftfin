//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemActionButtons {

    struct Record: View {

        @EnvironmentObject
        private var provider: ItemContentGroupProvider

        var body: some View {
            Content(item: provider.item)
        }
    }
}

extension ItemActionButtons.Record {

    private struct Content: View {

        @ViewContextContains(.isInMenu)
        private var isInMenu

        @Router
        private var router

        @StateObject
        private var viewModel: RecordingTimerViewModel

        init(item: BaseItemDto) {
            self._viewModel = StateObject(wrappedValue: RecordingTimerViewModel(item: item))
        }

        private var isSeries: Bool {
            viewModel.program?.isSeries == true
        }

        private var isScheduled: Bool {
            viewModel.recordingTimer != nil || viewModel.seriesRecordingTimer != nil
        }

        @ViewBuilder
        private var recordingButtons: some View {
            if let recordingTimer = viewModel.recordingTimer {
                Button(
                    recordingTimer.status == .inProgress ? L10n.stopRecording : L10n.cancelRecording,
                    systemImage: recordingTimer.status == .inProgress ? "stop.circle" : "xmark.circle",
                    role: .destructive
                ) {
                    viewModel.toggleRecording()
                }

                Button(L10n.recordingSettings, systemImage: "gearshape") {
                    router.route(to: .editRecordingTimer(viewModel: viewModel, isSeries: false))
                }
            } else {
                Button(
                    L10n.record,
                    systemImage: ItemActionButton.record.secondarySystemImage
                ) {
                    viewModel.toggleRecording()
                }
            }
        }

        var body: some View {
            Group {
                if isSeries || viewModel.recordingTimer != nil {
                    Menu(
                        ItemActionButton.record.displayTitle,
                        systemImage: isScheduled
                            ? ItemActionButton.record.systemImage
                            : ItemActionButton.record.secondarySystemImage
                    ) {
                        recordingButtons

                        if isSeries {
                            Divider()

                            if viewModel.seriesRecordingTimer == nil {
                                Button(
                                    L10n.recordSeries,
                                    systemImage: "smallcircle.filled.circle"
                                ) {
                                    viewModel.toggleSeriesRecording()
                                }
                            } else {
                                Button(
                                    L10n.cancelSeriesRecording,
                                    systemImage: "xmark.circle",
                                    role: .destructive
                                ) {
                                    viewModel.toggleSeriesRecording()
                                }

                                Button(L10n.seriesSettings, systemImage: "gearshape") {
                                    router.route(to: .editRecordingTimer(
                                        viewModel: viewModel,
                                        isSeries: true
                                    ))
                                }
                            }
                        }
                    }
                    .if(!isInMenu && UIDevice.isTV) { menu in
                        menu.menuStyle(.button)
                    }
                } else {
                    recordingButtons
                }
            }
            .isSelected(isScheduled)
            .enabled(viewModel.canManageRecordings)
            .onAppear {
                viewModel.refresh()
            }
            .onReceive(Notifications[.recordingTimersDidChange].publisher) {
                viewModel.refresh()
            }
            .errorMessage($viewModel.error)
        }
    }
}
