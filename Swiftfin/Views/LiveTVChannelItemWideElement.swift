//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LiveTVChannelItemWideElement: View {

    @FocusState
    private var focused: Bool
    @State
    private var loading: Bool = false
    @State
    private var isFocused: Bool = false

    var channel: BaseItemDto
    var currentProgram: BaseItemDto?
    var currentProgramText: LiveTVChannelViewProgram
    var nextProgramsText: [LiveTVChannelViewProgram]
    var onSelect: (@escaping (Bool) -> Void) -> Void

    var progressPercent: Double {
        if let currentProgram = currentProgram {
            let progressPercent = currentProgram.getLiveProgressPercentage()
            if progressPercent > 1.0 {
                return 1.0
            } else {
                return progressPercent
            }
        }
        return 0
    }

    private var detailText: String {
        guard let program = currentProgram else {
            return ""
        }
        var text = ""
        if let season = program.parentIndexNumber,
           let episode = program.indexNumber
        {
            text.append("\(season)x\(episode) ")
        } else if let episode = program.indexNumber {
            text.append("\(episode) ")
        }
        if let title = program.episodeTitle {
            text.append("\(title) ")
        }
        if let year = program.productionYear {
            text.append("\(year) ")
        }
        if let rating = program.officialRating {
            text.append("\(rating)")
        }
        return text
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    ZStack(alignment: .center) {
                        ImageView(channel.imageURL(.primary, maxWidth: 56))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)

                        if loading {

                            ProgressView()
                        }
                    }
                    .padding(.top, 4)
                    .padding(.leading, 4)

                    VStack(alignment: .leading) {
                        Text(channel.number != nil ? "\(channel.number ?? "") " : "")
                            .font(.body)
                            .lineLimit(1)
                            .foregroundColor(Color.jellyfinPurple)
                            .frame(alignment: .leading)
                            .padding(.init(top: 0, leading: 0, bottom: 4, trailing: 0))
                    }
                    .padding(.top, 4)
                }
                .frame(alignment: .leading)
                .opacity(loading ? 0.5 : 1.0)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(channel.name ?? "")")
                        .font(.body)
                        .bold()
                        .lineLimit(1)
                        .foregroundColor(Color.jellyfinPurple)
                        .frame(alignment: .leading)

                    progressBar()
                        .padding(.top, 4)

                    HStack {
                        Text(currentProgramText.timeDisplay)
                            .font(.footnote)
                            .bold()
                            .lineLimit(1)
                            .foregroundColor(Color("TextHighlightColor"))
                            .frame(width: 38, alignment: .leading)

                        Text(currentProgramText.title)
                            .font(.footnote)
                            .bold()
                            .lineLimit(1)
                            .foregroundColor(Color("TextHighlightColor"))
                    }
                    .padding(.top, 4)

                    if !nextProgramsText.isEmpty {
                        let nextItem = nextProgramsText[0]
                        programLabel(timeText: nextItem.timeDisplay, titleText: nextItem.title, color: Color.gray)
                    }
                    if nextProgramsText.count > 1 {
                        let nextItem2 = nextProgramsText[1]
                        programLabel(timeText: nextItem2.timeDisplay, titleText: nextItem2.title, color: Color.gray)
                    }

                    Spacer()
                }
                .padding(8)

                Spacer()
            }
        }
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.secondarySystemFill))
        .onTapGesture {
            onSelect { loadingState in
                loading = loadingState
            }
        }
    }

    @ViewBuilder
    func progressBar() -> some View {
        VStack(alignment: .center) {
            GeometryReader { gp in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray)
                        .opacity(0.4)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 6, maxHeight: 6)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.jellyfinPurple)
                        .frame(width: CGFloat(progressPercent * gp.size.width), height: 6)
                }
            }
            .frame(height: 6, alignment: .center)
        }
    }

    @ViewBuilder
    func programLabel(timeText: String, titleText: String, color: Color) -> some View {
        HStack(alignment: .top) {
            Text(timeText)
                .font(.footnote)
                .lineLimit(1)
                .foregroundColor(color)
                .frame(width: 38, alignment: .leading)
            Text(titleText)
                .font(.footnote)
                .lineLimit(1)
                .foregroundColor(color)
        }
    }
}
