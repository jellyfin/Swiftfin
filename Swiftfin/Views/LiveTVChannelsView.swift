//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Foundation
import JellyfinAPI
import SwiftUI

typealias LiveTVChannelViewProgram = (timeDisplay: String, title: String)

struct LiveTVChannelsView: View {

    @EnvironmentObject
    private var liveTVRouter: LiveTVCoordinator.Router
    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router

    @StateObject
    var viewModel = LiveTVChannelsViewModel()

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

        LiveTVChannelItemWideElement(
            channel: channel,
            currentProgram: channelProgram.currentProgram,
            currentProgramText: currentProgramDisplayText,
            nextProgramsText: nextProgramsDisplayText(
                nextItems: nextItems,
                timeFormatter: viewModel.timeFormatter
            ),
            onSelect: { _ in
                mainRouter.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: channel, mediaSource: channel.mediaSources!.first!))
            }
        )
    }

    var body: some View {

        if viewModel.isLoading {
            ProgressView()
        } else if viewModel.channelPrograms.isNotEmpty {

            CollectionView(items: viewModel.channelPrograms) { _, program, _ in
                channelCell(for: program)
            }
            .layout { _, layoutEnvironment in
                .grid(
                    layoutEnvironment: layoutEnvironment,
                    layoutMode: .adaptive(withMinItemSize: 250),
                    itemSpacing: 16,
                    lineSpacing: 4,
                    itemSize: .fractionalWidth(1 / 3)
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
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
                    viewModel.getChannels()
                } label: {
                    Text(L10n.reload)
                }
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

private extension BaseItemDto {
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
