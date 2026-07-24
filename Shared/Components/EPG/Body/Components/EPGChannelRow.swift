//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct EPGChannelRow: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    private var viewModel: EPGViewModel
    @ObservedObject
    private var proxy: EPGProxy

    private let channel: BaseItemDto
    private let action: (BaseItemDto) -> Void

    private let layout = EPGLayout()

    init(
        viewModel: EPGViewModel,
        channel: BaseItemDto,
        action: @escaping (BaseItemDto) -> Void
    ) {
        self.viewModel = viewModel
        self.proxy = viewModel.proxy
        self.channel = channel
        self.action = action
    }

    var body: some View {
        let contentWidth = max(layout.width(from: viewModel.startDate, to: viewModel.endDate), 1)
        let window = proxy.visibleWindow
        let visiblePrograms = (viewModel.programs[channel.id ?? ""] ?? []).filter {
            $0.leadingOffset < window.upperBound && $0.leadingOffset + $0.width > window.lowerBound
        }

        ZStack(alignment: .leading) {
            Color.clear
                .frame(width: contentWidth, height: layout.rowHeight)

            ForEach(visiblePrograms) { block in
                EPGProgramCell(
                    block: block,
                    now: viewModel.now
                ) { item in
                    action(item)
                }
                .offset(x: block.leadingOffset)
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: layout.rowHeight,
            maxHeight: layout.rowHeight,
            alignment: .leading
        )
        .fixedSize(horizontal: false, vertical: true)
        .tint(accentColor)
    }
}
