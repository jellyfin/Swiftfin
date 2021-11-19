//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */


import SwiftUI
import JellyfinAPI

struct LiveTVChannelItemElement: View {
    @Environment(\.isFocused) var envFocused: Bool
    @State var focused: Bool = false
    
    var channel: BaseItemDto
    var program: BaseItemDto?
    
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "h:mm"
        return df
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(channel.number ?? "")
                    .font(.footnote)
                    .frame(alignment: .trailing)
            }.frame(alignment: .top)
            ImageView(src: channel.getPrimaryImage(maxWidth: 125))
                .frame(width: 125, alignment: .center)
                .offset(x: 0, y: -32)
            Text(channel.name ?? "?")
                .font(.footnote)
                .lineLimit(1)
                .frame(alignment: .center)
            if let currentProgram = program {
                Text(currentProgram.name ?? "")
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(.green)
            }
            
            if let currentProgram = program,
               let startDate = currentProgram.startDate,
               let endDate = currentProgram.endDate {
                let start = startDate.timeIntervalSinceReferenceDate
                let end = endDate.timeIntervalSinceReferenceDate
                let now = Date().timeIntervalSinceReferenceDate
                let length = end - start
                let progress = now - start
                let progPercent = progress / length
                VStack {
                    HStack {
                        Text(dateFormatter.string(from: startDate))
                            .font(.footnote)
                            .lineLimit(1)
                            .frame(alignment: .leading)
                        
                        Spacer()
                        
                        Text(dateFormatter.string(from: endDate))
                            .font(.footnote)
                            .lineLimit(1)
                            .frame(alignment: .trailing)
                    }
                    GeometryReader { gp in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray)
                                .opacity(0.4)
                            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 12, maxHeight: 12)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(red: 172/255, green: 92/255, blue: 195/255))
                                .frame(width: CGFloat(progPercent * gp.size.width), height: 12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.clear)
        .border(focused ? Color.blue : Color.clear, width: 4)
        .onChange(of: envFocused) { envFocus in
            withAnimation(.linear(duration: 0.15)) {
                self.focused = envFocus
            }
        }
        .scaleEffect(focused ? 1.1 : 1)
    }
}
