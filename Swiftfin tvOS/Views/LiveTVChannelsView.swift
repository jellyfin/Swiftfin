//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Foundation
import JellyfinAPI
import SwiftUI

typealias LiveTVChannelViewProgram = (timeDisplay: String, title: String)

struct LiveTVChannelsView: View {

    @EnvironmentObject
    private var router: LiveTVChannelsCoordinator.Router

    @StateObject
    var viewModel = LiveTVChannelsViewModel()

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

    // TODO: add retry
    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }

    @ViewBuilder
    private var channelsView: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.elements.isNotEmpty {
                CollectionVGrid(
                    $viewModel.elements,
                    layout: .minWidth(400, itemSpacing: 16, lineSpacing: 4)
                ) { program in
                    channelCell(for: program)
                }
                .onReachedBottomEdge(offset: .offset(300)) {
                    viewModel.send(.getNextPage)
                }
                .onAppear {
                    viewModel.startScheduleCheckTimer()
                }
                .onDisappear {
                    viewModel.stopScheduleCheckTimer()
                }
            } else {
                VStack {
                    Text(L10n.noResults)
                    Button {
                        viewModel.send(.refresh)
                    } label: {
                        Text(L10n.reload)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func channelCell(for channelProgram: LiveTVChannelProgram) -> some View {
        let channel = channelProgram.channel
        let currentProgramDisplayText = channelProgram.currentProgram?
            .programDisplayText(timeFormatter: viewModel.timeFormatter) ?? LiveTVChannelViewProgram(timeDisplay: "", title: "")
        let nextItems = channelProgram.programs.filter { program in
            guard let start = program.startDate else {
                return false
            }
            guard let currentStart = channelProgram.currentProgram?.startDate else {
                return false
            }
            return start > currentStart
        }

        LiveTVChannelItemElement(
            channel: channel,
            currentProgram: channelProgram.currentProgram,
            currentProgramText: currentProgramDisplayText,
            nextProgramsText: nextProgramsDisplayText(
                nextItems: nextItems,
                timeFormatter: viewModel.timeFormatter
            ),
            onSelect: { _ in
                guard let mediaSource = channel.mediaSources?.first else {
                    return
                }
                viewModel.stopScheduleCheckTimer()
                router.route(
                    to: \.liveVideoPlayer,
                    LiveVideoPlayerManager(item: channel, mediaSource: mediaSource, program: channelProgram)
                )
            }
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.elements.isEmpty {
                loadingView
            } else if viewModel.elements.isEmpty {
                noResultsView
            } else {
                channelsView
            }
        }
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.send(.refresh)
            }
        }
    }

    private func nextProgramsDisplayText(nextItems: [BaseItemDto], timeFormatter: DateFormatter) -> [LiveTVChannelViewProgram] {
        var programsDisplayText: [LiveTVChannelViewProgram] = []
        for item in nextItems {
            programsDisplayText.append(item.programDisplayText(timeFormatter: timeFormatter))
        }
        return programsDisplayText
    }
}

extension BaseItemDto {
    func programDisplayText(timeFormatter: DateFormatter) -> LiveTVChannelViewProgram {
        var timeText = ""
        if let start = self.startDate {
            timeText.append(timeFormatter.string(from: start) + " ")
        }
        var displayText = ""
        if let season = self.parentIndexNumber,
           let episode = self.indexNumber
        {
            displayText.append("\(season)x\(episode) ")
        } else if let episode = self.indexNumber {
            displayText.append("\(episode) ")
        }
        if let name = self.name {
            displayText.append("\(name) ")
        }
        if let title = self.episodeTitle {
            displayText.append("\(title) ")
        }
        if let year = self.productionYear {
            displayText.append("\(year) ")
        }
        if let rating = self.officialRating {
            displayText.append("\(rating)")
        }

        return LiveTVChannelViewProgram(timeDisplay: timeText, title: displayText)
    }
}
