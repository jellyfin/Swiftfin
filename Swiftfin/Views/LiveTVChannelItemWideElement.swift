//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
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
            HStack {
                ZStack(alignment: .center) {
                    ImageView(channel.getPrimaryImage(maxWidth: 128))
                        .aspectRatio(contentMode: .fit)
                        .padding(.init(top: 0, leading: 0, bottom: 8, trailing: 0))
                    VStack(alignment: .center) {
                        Spacer()
                            .frame(maxHeight: .infinity)
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
                        .padding(.init(top: 0, leading: 4, bottom: 0, trailing: 4))
                    }
                    if loading {
                        
                        ProgressView()
                          
                    }
                }
                .aspectRatio(1.0, contentMode: .fit)
                VStack(alignment: .leading) {
                    let channelNumber = channel.number != nil ? "\(channel.number ?? "") " : ""
                    let channelName = "\(channelNumber)\(channel.name ?? "?")"
                    Text(channelName)
                        .font(.body)
                        .lineLimit(1)
                        .frame(alignment: .leading)
                    HStack(alignment: .top) {
                        Text(currentProgramText.timeDisplay)
                            .font(.footnote)
                            .lineLimit(2)
                            .foregroundColor(.green)
                            .frame(width: 40)
                        Text(currentProgramText.title)
                            .font(.footnote)
                            .lineLimit(2)
                            .foregroundColor(.green)
                    }
                    if nextProgramsText.count > 0,
                       let nextItem = nextProgramsText[0] {
                        HStack(alignment: .top) {
                            Text(nextItem.timeDisplay)
                                .font(.footnote)
                                .lineLimit(2)
                                .foregroundColor(.gray)
                                .frame(width: 40)
                            Text(nextItem.title)
                                .font(.footnote)
                                .lineLimit(2)
                                .foregroundColor(.gray)
                        }
                    }
                    if nextProgramsText.count > 1,
                       let nextItem2 = nextProgramsText[1] {
                        HStack(alignment: .top) {
                            Text(nextItem2.timeDisplay)
                                .font(.footnote)
                                .lineLimit(2)
                                .foregroundColor(.gray)
                                .frame(width: 40)
                            Text(nextItem2.title)
                                .font(.footnote)
                                .lineLimit(2)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
            .frame(alignment: .leading)
            .padding()
            .opacity(loading ? 0.5 : 1.0)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color("BackgroundColor"))
        )
        .frame(height: 128)
        .onTapGesture {
            onSelect { loadingState in
                loading = loadingState
            }
        }
    }
}
