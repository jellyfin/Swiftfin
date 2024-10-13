//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: match `CapsuleSlider` with `total` handling

struct ThumbSlider: View {

    @Default(.VideoPlayer.Overlay.sliderColor)
    private var sliderColor

    @Binding
    private var isEditing: Bool
    @Binding
    private var progress: Double

    private var trackMask: () -> any View

    var body: some View {
        SwiftfinSlider(progress: $progress)
            .onEditingChanged { isEditing in
                self.isEditing = isEditing
            }
            .track {
                Capsule()
                    .foregroundColor(sliderColor)
                    .frame(height: 5)
            }
            .trackBackground {
                Capsule()
                    .foregroundColor(Color.gray)
                    .opacity(0.5)
                    .frame(height: 5)
            }
            .thumb {
                ZStack {
                    Color.clear
                        .frame(height: 25)

                    Circle()
                        .foregroundColor(sliderColor)
                        .frame(width: isEditing ? 25 : 20)
                }
                .overlay {
                    Color.clear
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                }
            }
            .trackMask(trackMask)
    }
}

extension ThumbSlider {

    init(progress: Binding<Double>) {
        self.init(
            isEditing: .constant(false),
            progress: progress,
            trackMask: { Color.white }
        )
    }

    func isEditing(_ isEditing: Binding<Bool>) -> Self {
        copy(modifying: \._isEditing, with: isEditing)
    }

    func trackMask(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trackMask, with: content)
    }
}
