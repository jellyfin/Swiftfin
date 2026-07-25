//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct RecordingEditorView: View {

    @ObservedObject
    private var viewModel: ProgramTimerViewModel

    @Router
    private var router

    @State
    private var timer: TimerInfoDto
    @State
    private var seriesTimer: SeriesTimerInfoDto

    private let isSeries: Bool

    private var prePaddingMinutes: Binding<Int> {
        if isSeries {
            Binding(
                get: { (seriesTimer.prePaddingSeconds ?? 0) / 60 },
                set: { seriesTimer.prePaddingSeconds = $0 * 60 }
            )
        } else {
            Binding(
                get: { (timer.prePaddingSeconds ?? 0) / 60 },
                set: { timer.prePaddingSeconds = $0 * 60 }
            )
        }
    }

    private var postPaddingMinutes: Binding<Int> {
        if isSeries {
            Binding(
                get: { (seriesTimer.postPaddingSeconds ?? 0) / 60 },
                set: { seriesTimer.postPaddingSeconds = $0 * 60 }
            )
        } else {
            Binding(
                get: { (timer.postPaddingSeconds ?? 0) / 60 },
                set: { timer.postPaddingSeconds = $0 * 60 }
            )
        }
    }

    private func save() {
        if isSeries {
            viewModel.updateSeriesTimer(seriesTimer)
        } else {
            viewModel.updateTimer(timer)
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

            if isSeries {
                seriesSections
            }
        }
        .backport
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

    @ViewBuilder
    private var seriesSections: some View {
        Section {
            Picker(L10n.record, selection: $seriesTimer.isRecordNewOnly.coalesce(false)) {
                Text(L10n.newEpisodesOnly)
                    .tag(true)
                Text(L10n.allEpisodes)
                    .tag(false)
            }

            Picker(L10n.channels, selection: $seriesTimer.isRecordAnyChannel.coalesce(false)) {
                Text(seriesTimer.channelName ?? L10n.oneChannel)
                    .tag(false)
                Text(L10n.allChannels)
                    .tag(true)
            }

            Picker(L10n.airTime, selection: $seriesTimer.isRecordAnyTime.coalesce(false)) {
                Text(seriesTimer.startDate?.formatted(date: .omitted, time: .shortened) ?? L10n.airTime)
                    .tag(false)
                Text(L10n.anytime)
                    .tag(true)
            }

            Picker(L10n.retain, selection: $seriesTimer.keepUpTo.coalesce(0)) {
                Text(L10n.asManyAsPossible)
                    .tag(0)
                ForEach(1 ..< 11) { count in
                    Text(count.description)
                        .tag(count)
                }
            }

            Toggle(L10n.skipDuplicates, isOn: $seriesTimer.isSkipEpisodesInLibrary.coalesce(false))
        } header: {
            Text(L10n.series)
        } footer: {
            Text(L10n.episodeComparisonDescription)
        }
    }
}

extension RecordingEditorView {

    /// Edit a single timer
    init(timer viewModel: ProgramTimerViewModel) {
        self.viewModel = viewModel
        self.isSeries = false
        self._timer = State(initialValue: viewModel.timer ?? TimerInfoDto())
        self._seriesTimer = State(initialValue: SeriesTimerInfoDto())
    }

    /// Edit a series timer
    init(seriesTimer viewModel: ProgramTimerViewModel) {
        self.viewModel = viewModel
        self.isSeries = true
        self._timer = State(initialValue: TimerInfoDto())
        self._seriesTimer = State(initialValue: viewModel.seriesTimer ?? SeriesTimerInfoDto())
    }
}
