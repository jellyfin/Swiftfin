//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: scroll if description too long

@MainActor
struct MediaInfoSupplement {

    let displayTitle: String = L10n.info
    @SharedBaseItem
    var item: BaseItemDto

    nonisolated let id: String

    init(item: BaseItemDto) {
        self.item = item
        self.id = "MediaInfo-\(item.id ?? "any")"
    }
}

extension MediaInfoSupplement: VideoPlayerSupplement {

    var body: some View {
        InfoOverlay(item: item)
    }

    private struct InfoOverlay: PresentationView {

        @AdaptiveLayout
        private var viewLayout

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        @SharedBaseItem
        private var item: BaseItemDto

        @StateObject
        private var recordingViewModel: RecordingTimerViewModel

        @State
        private var endsAtLabel: String?

        init(item: BaseItemDto) {
            self.item = item
            self._recordingViewModel = StateObject(wrappedValue: RecordingTimerViewModel(item: item))
        }

        private var accessoryView: some View {
            VStack(alignment: .leading) {
                DotHStack {
                    if item.type == .episode {
                        if let premiereDateLabel = item.premiereDateLabel {
                            Text(premiereDateLabel)
                        }

                        if let seasonEpisodeLocator = item.seasonEpisodeLabel {
                            Text(seasonEpisodeLocator)
                        }
                    } else if let premiereYear = item.premiereDateYear {
                        Text(premiereYear)
                    }

                    if let runtime = item.runTimeLabel {
                        Text(runtime)
                    }

                    if let officialRating = item.officialRating {
                        Text(officialRating)
                    }

                    if let endsAtLabel {
                        Text(endsAtLabel)
                    }
                }
            }
            .onChange(of: mediaSession.seconds, initial: true) { _, seconds in
                let newLabel = makeEndsAtLabel(seconds: seconds)

                if newLabel != endsAtLabel {
                    endsAtLabel = newLabel
                }
            }
        }

        @ViewBuilder
        private var recordButtons: some View {
            VStack {
                Button(role: recordingViewModel.recordingTimer != nil ? .destructive : nil) {
                    recordingViewModel.toggleRecording()
                } label: {
                    Group {
                        if let recordingTimer = recordingViewModel.recordingTimer {
                            Label(
                                recordingTimer.status == .inProgress ? L10n.stopRecording : L10n.cancelRecording,
                                systemImage: "record.circle.fill"
                            )
                        } else {
                            Label(L10n.record, systemImage: "record.circle")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
                .buttonStyle(.supplementAction)
                .frame(height: viewLayout.supplementLogoHeight)

                if recordingViewModel.program?.isSeries == true {
                    Button(role: recordingViewModel.seriesRecordingTimer != nil ? .destructive : nil) {
                        recordingViewModel.toggleSeriesRecording()
                    } label: {
                        Group {
                            if recordingViewModel.seriesRecordingTimer != nil {
                                Label(L10n.cancelSeriesRecording, systemImage: "smallcircle.filled.circle.fill")
                            } else {
                                Label(L10n.recordSeries, systemImage: "smallcircle.filled.circle")
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    }
                    .buttonStyle(.supplementAction)
                    .frame(height: viewLayout.supplementLogoHeight)
                }
            }
            .enabled(recordingViewModel.canManageRecordings)
            #if os(tvOS)
            .focusSection()
            #endif
            .onAppear {
                recordingViewModel.refresh()
            }
            .onReceive(Notifications[.recordingTimersDidChange].publisher) {
                recordingViewModel.refresh()
            }
            .errorMessage($recordingViewModel.error)
        }

        private var fromBeginningButton: some View {
            Button {
                mediaSession.seek(to: .zero)
                mediaSession.setPlaybackRequestStatus(status: .playing)
                viewState.selectedSupplementID = nil
            } label: {
                Label(L10n.fromBeginning, systemImage: "play.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.supplementAction)
            .frame(height: viewLayout.supplementLogoHeight)
        }

        // TODO: may need to be a layout for correct overview frame
        //       with scrolling if too long
        var standardView: some View {
            CompactOrRegularView(
                isCompact: viewState.isCompact
            ) {
                compactView
            } regularView: {
                regularContent
                    .edgePadding()
            }
            .padding(.leading, viewState.supplementInsets.leading)
            .padding(.trailing, viewState.supplementInsets.trailing)
            .task(id: item.currentProgram?.id) {
                await recordingViewModel.refresh()
            }
        }

        private var compactView: some View {
            VStack(alignment: .leading) {
                Text(item.displayTitle)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let currentProgram = item.currentProgram {
                    Text(currentProgram.displayTitle)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                }

                if let overview = item.overview ?? item.currentProgram?.overview {
                    Text(overview)
                        .font(.subheadline)
                        .fontWeight(.regular)
                }

                accessoryView
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !item.isLiveStream {
                    fromBeginningButton
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .padding(.vertical)
                } else if item.canBeRecorded {
                    recordButtons
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .edgePadding()
        }

        private var regularContent: some View {
            HStack(alignment: .bottom, spacing: viewLayout.edgePadding) {
                // TODO: determine what to do with non-portrait (channel, home video) images
                //       - use aspect ratio?
                PosterImage(
                    item: item,
                    type: item.preferredPosterDisplayType,
                    contentMode: .fit
                )
                .posterCornerRadius(item.preferredPosterDisplayType)
                .withViewContext(.isOverComplexContent)

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if let currentProgram = item.currentProgram {
                        Text(currentProgram.displayTitle)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                    }

                    if let overview = item.overview ?? item.currentProgram?.overview {
                        Text(overview)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .lineLimit(4)
                    }

                    accessoryView
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !item.isLiveStream {
                    AlternateLayoutView {
                        Label(L10n.fromBeginning, systemImage: "play.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding()
                            .edgePadding(.horizontal)
                            .frame(height: viewLayout.supplementRowHeight)
                    } content: {
                        fromBeginningButton
                    }
                } else if item.canBeRecorded {
                    recordButtons
                }
            }
        }

        var largeView: some View {
            regularContent
                .edgePadding(.horizontal)
                .padding(.vertical, viewLayout.edgePadding / 2)
                .background {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Material.thin)
                }
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .edgePadding()
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .focusSection()
                .task(id: item.currentProgram?.id) {
                    await recordingViewModel.refresh()
                }
        }

        private func makeEndsAtLabel(seconds: Duration) -> String? {
            guard !item.isLiveStream,
                  item.type != .recording,
                  let runtime = item.runtime,
                  runtime > .zero,
                  mediaSession.rate > 0
            else { return nil }

            let remaining = max(runtime - seconds, .zero)
            let endDate = Date.now.addingTimeInterval(remaining.seconds / mediaSession.rate)

            return L10n.endsAt(endDate.formatted(date: .omitted, time: .shortened))
        }
    }
}
