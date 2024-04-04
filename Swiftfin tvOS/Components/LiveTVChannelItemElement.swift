//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LiveTVChannelItemElement: View {

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
            VStack {
                HStack {
                    Text(channel.number ?? "")
                        .font(.footnote)
                        .frame(alignment: .leading)
                        .padding()
                    Spacer()
                }.frame(alignment: .top)
                Spacer()
            }

            GeometryReader { gp in
                VStack {
                    ImageView(channel.imageSource(.primary, maxWidth: 192))
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 192, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.init(top: 16, leading: 8, bottom: gp.size.height / 2, trailing: 0))
                VStack {
                    Text(channel.name ?? "?")
                        .font(.footnote)
                        .lineLimit(1)
                        .frame(alignment: .center)
                        .foregroundColor(Color.jellyfinPurple)
                        .padding(.init(top: 0, leading: 0, bottom: 8, trailing: 0))

                    programLabel(
                        timeText: currentProgramText.timeDisplay,
                        titleText: currentProgramText.title,
                        color: Color.primary,
                        font: Font.system(size: 20, weight: .bold, design: .default)
                    )
                    if nextProgramsText.isNotEmpty {
                        let nextItem = nextProgramsText[0]
                        programLabel(
                            timeText: nextItem.timeDisplay,
                            titleText: nextItem.title,
                            color: Color.gray,
                            font: Font.system(size: 20, design: .default)
                        )
                    }
                    if nextProgramsText.count > 1 {
                        let nextItem2 = nextProgramsText[1]
                        programLabel(
                            timeText: nextItem2.timeDisplay,
                            titleText: nextItem2.title,
                            color: Color.gray,
                            font: Font.system(size: 20, design: .default)
                        )
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.init(top: gp.size.height / 2, leading: 16, bottom: 56, trailing: 16))
                .opacity(loading ? 0.5 : 1.0)
            }

            if loading {
                ProgressView()
            }

            VStack {
                GeometryReader { gp in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray)
                            .opacity(0.4)
                            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 8, maxHeight: 8)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.jellyfinPurple)
                            .frame(width: CGFloat(progressPercent * gp.size.width), height: 8)
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.init(top: 0, leading: 16, bottom: 32, trailing: 16))
                }
            }
        }
        .frame(minWidth: 400, minHeight: 400)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 4)
        )
        .cornerRadius(20)
        .scaleEffect(isFocused ? 1.1 : 1)
        .focusable(true)
        .focused($focused)
        .onChange(of: focused) { foc in
            withAnimation(.linear(duration: 0.15)) {
                self.isFocused = foc
            }
        }
        .onLongPressGesture(minimumDuration: 0.01, pressing: { _ in }) {
            onSelect { loadingState in
                loading = loadingState
            }
        }
    }

    @ViewBuilder
    func programLabel(timeText: String, titleText: String, color: Color, font: Font) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(timeText)
                .font(font)
                .lineLimit(1)
                .foregroundColor(color)
                .frame(width: 54, alignment: .leading)
            Text(titleText)
                .font(font)
                .lineLimit(2)
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
