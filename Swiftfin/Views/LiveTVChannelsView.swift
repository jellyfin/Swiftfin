//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import ASCollectionView
import Foundation
import JellyfinAPI
import SwiftUI
import SwiftUICollection

typealias LiveTVChannelViewProgram = (timeDisplay: String, title: String)

struct LiveTVChannelsView: View {
    @EnvironmentObject
    private var liveTVRouter: LiveTVCoordinator.Router
    @StateObject
    var viewModel = LiveTVChannelsViewModel()
    @State
    private var isPortrait = false
    private var columns: Int {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 2
        } else {
            if isPortrait {
                return 1
            } else {
                return 2
            }
        }
    }

    var body: some View {
        if viewModel.isLoading == true {
            ProgressView()
        } else if !viewModel.channelPrograms.isEmpty {
            ASCollectionView(data: viewModel.channelPrograms, dataID: \.self) { channelProgram, _ in
                makeCellView(channelProgram)
            }
            .layout {
                .grid(
                    layoutMode: .fixedNumberOfColumns(columns),
                    itemSpacing: 16,
                    lineSpacing: 4,
                    itemSize: .absolute(144)
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .onAppear {
                viewModel.startScheduleCheckTimer()
                self.checkOrientation()
            }
            .onDisappear {
                viewModel.stopScheduleCheckTimer()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                self.checkOrientation()
            }
        } else {
            VStack {
                Text("No results.")
                Button {
                    viewModel.getChannels()
                } label: {
                    Text("Reload")
                }
            }
        }
    }

    @ViewBuilder
    func makeCellView(_ channelProgram: LiveTVChannelProgram) -> some View {
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
            onSelect: { loadingAction in
                loadingAction(true)
                self.viewModel.fetchVideoPlayerViewModel(item: channel) { playerViewModel in
                    self.liveTVRouter.route(to: \.videoPlayer, playerViewModel)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        loadingAction(false)
                    }
                }
            }
        )
    }

    private func checkOrientation() {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        guard let scene = windowScene else { return }
        self.isPortrait = scene.interfaceOrientation.isPortrait
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
