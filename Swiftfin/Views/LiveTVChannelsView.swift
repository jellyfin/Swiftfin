//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI
import SwiftUICollection

typealias LiveTVChannelViewProgram = (timeDisplay: String, title: String)

struct LiveTVChannelsView: View {
    @EnvironmentObject
    var router: LiveTVCoordinator.Router
    @StateObject
    var viewModel = LiveTVChannelsViewModel()
    @State private var isPortrait = false
    
    var body: some View {
        if viewModel.isLoading == true {
            ProgressView()
        } else if !viewModel.rows.isEmpty {
            CollectionView(rows: viewModel.rows) { _, _ in
                createGridLayout()
            } cell: { indexPath, cell in
                makeCellView(indexPath: indexPath, cell: cell)
            } supplementaryView: { _, indexPath in
                EmptyView()
                    .accessibilityIdentifier("\(indexPath.section).\(indexPath.row)")
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
    func makeCellView(indexPath: IndexPath, cell: LiveTVChannelRowCell) -> some View {
        let item = cell.item
        let channel = item.channel
        let currentProgramDisplayText = item.currentProgram?.programDisplayText(timeFormatter: viewModel.timeFormatter) ?? LiveTVChannelViewProgram(timeDisplay: "", title: "")
        let nextItems = item.programs.filter { program in
            guard let start = program.startDate else {
                return false
            }
            guard let currentStart = item.currentProgram?.startDate else {
                return false
            }
            return start > currentStart
        }
        LiveTVChannelItemWideElement(channel: channel,
                                     currentProgram: item.currentProgram,
                                     currentProgramText: currentProgramDisplayText,
                                     nextProgramsText: nextProgramsDisplayText(nextItems: nextItems, timeFormatter: viewModel.timeFormatter),
                                     onSelect: { loadingAction in
                loadingAction(true)
                self.viewModel.fetchVideoPlayerViewModel(item: channel) { playerViewModel in
                self.router.route(to: \.videoPlayer, playerViewModel)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    loadingAction(false)
                }
            }
        })
    }
    
    private func createGridLayout() -> NSCollectionLayoutSection {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .absolute((UIScreen.main.bounds.width / 2) - 2),
                heightDimension: .fractionalHeight(1)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                leading: .flexible(0), top: nil,
                trailing: .flexible(2), bottom: .flexible(2)
            )
            let item2 = NSCollectionLayoutItem(layoutSize: itemSize)
            item2.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                leading: nil, top: nil,
                trailing: .flexible(0), bottom: .flexible(2)
            )
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(132)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item, item2]
            )
            let section = NSCollectionLayoutSection(group: group)
            return section
        } else {
            if isPortrait {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .absolute(UIScreen.main.bounds.width - 2),
                    heightDimension: .fractionalHeight(1)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: .flexible(0), top: nil,
                    trailing: .flexible(2), bottom: .flexible(2)
                )
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(132)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                let section = NSCollectionLayoutSection(group: group)
                return section
            } else {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.49),
                    heightDimension: .fractionalHeight(1)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: .flexible(0), top: nil,
                    trailing: .flexible(2), bottom: .flexible(2)
                )
                let item2 = NSCollectionLayoutItem(layoutSize: itemSize)
                item2.edgeSpacing = NSCollectionLayoutEdgeSpacing(
                    leading: nil, top: nil,
                    trailing: .flexible(0), bottom: .flexible(2)
                )
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(132)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item, item2]
                )
                let section = NSCollectionLayoutSection(group: group)
                return section
            }
        }
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
    func programDisplayText(timeFormatter: DateFormatter)  -> LiveTVChannelViewProgram {
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
