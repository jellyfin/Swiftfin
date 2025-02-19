//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct VersionMenu: View {

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        @ObservedObject
        var viewModel: ItemViewModel

        let mediaSources: [MediaSourceInfo]

        // MARK: - Body

        var body: some View {
            Menu {
                ForEach(mediaSources, id: \.hashValue) { mediaSource in
                    Button {
                        viewModel.send(.selectMediaSource(mediaSource))
                    } label: {
                        if let selectedMediaSource = viewModel.selectedMediaSource, selectedMediaSource == mediaSource {
                            Label(selectedMediaSource.displayTitle, systemImage: "checkmark")
                        } else {
                            Text(mediaSource.displayTitle)
                        }
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isFocused ? Color.white : Color.white.opacity(0.5))

                    Label(L10n.version, systemImage: "list.dash")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .labelStyle(.iconOnly)
                }
            }
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.20 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .menuStyle(.borderlessButton)
        }
    }
}
