//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EditRecordingView: View {

    @ObservedObject
    private var viewModel: RecordingTimerViewModel

    @Router
    private var router

    @State
    private var recordingTimer: TimerInfoDto
    @State
    private var seriesRecordingTimer: SeriesTimerInfoDto?

    init(viewModel: RecordingTimerViewModel, isSeries: Bool) {
        self.viewModel = viewModel
        self._recordingTimer = State(initialValue: viewModel.recordingTimer ?? TimerInfoDto())
        self._seriesRecordingTimer = State(initialValue: isSeries ? viewModel.seriesRecordingTimer : nil)
    }

    private var prePaddingMinutes: Binding<Int> {
        if seriesRecordingTimer != nil {
            Binding(
                get: { (seriesRecordingTimer?.prePaddingSeconds ?? 0) / 60 },
                set: { seriesRecordingTimer?.prePaddingSeconds = $0 * 60 }
            )
        } else {
            Binding(
                get: { (recordingTimer.prePaddingSeconds ?? 0) / 60 },
                set: { recordingTimer.prePaddingSeconds = $0 * 60 }
            )
        }
    }

    private var postPaddingMinutes: Binding<Int> {
        if seriesRecordingTimer != nil {
            Binding(
                get: { (seriesRecordingTimer?.postPaddingSeconds ?? 0) / 60 },
                set: { seriesRecordingTimer?.postPaddingSeconds = $0 * 60 }
            )
        } else {
            Binding(
                get: { (recordingTimer.postPaddingSeconds ?? 0) / 60 },
                set: { recordingTimer.postPaddingSeconds = $0 * 60 }
            )
        }
    }

    private func save() {
        if let seriesRecordingTimer {
            viewModel.updateSeriesRecordingTimer(seriesRecordingTimer)
        } else {
            viewModel.updateRecordingTimer(recordingTimer)
        }
    }

    @ViewBuilder
    private func seriesSections(_ seriesRecordingTimer: Binding<SeriesTimerInfoDto>) -> some View {
        Section {
            Picker(L10n.record, selection: seriesRecordingTimer.isRecordNewOnly.coalesce(false)) {
                Text(L10n.newEpisodesOnly)
                    .tag(true)
                Text(L10n.allEpisodes)
                    .tag(false)
            }

            Picker(L10n.channels, selection: seriesRecordingTimer.isRecordAnyChannel.coalesce(false)) {
                Text(seriesRecordingTimer.wrappedValue.channelName ?? L10n.oneChannel)
                    .tag(false)
                Text(L10n.allChannels)
                    .tag(true)
            }

            Picker(L10n.airTime, selection: seriesRecordingTimer.isRecordAnyTime.coalesce(false)) {
                Text(seriesRecordingTimer.wrappedValue.startDate?.formatted(date: .omitted, time: .shortened) ?? L10n.airTime)
                    .tag(false)
                Text(L10n.anytime)
                    .tag(true)
            }

            Picker(L10n.retain, selection: seriesRecordingTimer.keepUpTo.coalesce(0)) {
                Text(L10n.asManyAsPossible)
                    .tag(0)

                ForEach(1 ..< 11) { count in
                    Text(count.description)
                        .tag(count)
                }
            }

            Toggle(L10n.skipDuplicates, isOn: seriesRecordingTimer.isSkipEpisodesInLibrary.coalesce(false))
        } header: {
            Text(L10n.series)
        } footer: {
            Text(L10n.episodeComparisonDescription)
        }
    }

    var body: some View {
        Form(systemImage: "recordingtape") {
            Section(L10n.padding) {
                Stepper(L10n.minutesBefore, value: prePaddingMinutes, in: 0 ... 60, step: 1) {
                    LabeledContent(L10n.minutesBefore) {
                        Text(prePaddingMinutes.wrappedValue.description)
                            .foregroundStyle(.secondary)
                    }
                }

                Stepper(L10n.minutesAfter, value: postPaddingMinutes, in: 0 ... 60, step: 1) {
                    LabeledContent(L10n.minutesAfter) {
                        Text(postPaddingMinutes.wrappedValue.description)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let seriesRecordingTimer = Binding($seriesRecordingTimer) {
                seriesSections(seriesRecordingTimer)
            }
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.recording)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            } else {
                Button(L10n.save, action: save)
                    .backport
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
    }
}
