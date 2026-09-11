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

        @Router
        private var router

        @ViewContextContains(.isInMenu)
        private var isInMenu

        @StateObject
        private var viewModel: ProgramTimerViewModel

        init(item: BaseItemDto) {
            self._viewModel = StateObject(wrappedValue: ProgramTimerViewModel(item: item))
        }

        private var isSeries: Bool {
            viewModel.program.isSeries == true
        }

        private var isScheduled: Bool {
            viewModel.timer != nil || viewModel.seriesTimer != nil
        }

        @ViewBuilder
        private var timerButtons: some View {
            if let timer = viewModel.timer {
                Button(
                    timer.status == .inProgress ? L10n.stopRecording : L10n.cancelRecording,
                    systemImage: timer.status == .inProgress ? "stop.circle" : "xmark.circle",
                    role: .destructive
                ) {
                    viewModel.toggleRecording()
                }

                Button(L10n.recordingSettings, systemImage: "gearshape") {
                    router.route(to: .timerEditor(viewModel: viewModel))
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
                if isSeries || viewModel.timer != nil {
                    Menu(
                        ItemActionButton.record.displayTitle,
                        systemImage: isScheduled
                            ? ItemActionButton.record.systemImage
                            : ItemActionButton.record.secondarySystemImage
                    ) {
                        timerButtons

                        if isSeries {
                            Divider()

                            if viewModel.seriesTimer == nil {
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
                                    router.route(to: .seriesTimerEditor(viewModel: viewModel))
                                }
                            }
                        }
                    }
                    .if(!isInMenu && UIDevice.isTV) { menu in
                        menu.menuStyle(.button)
                    }
                } else {
                    timerButtons
                }
            }
            .isSelected(isScheduled)
            .onAppear {
                viewModel.refresh()
            }
        }
    }
}
