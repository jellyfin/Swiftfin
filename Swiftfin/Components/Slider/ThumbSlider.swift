//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ThumbSlider: View {

    @Binding
    private var progress: CGFloat
    @State
    private var isEditing: Bool = false
    private var onEditingChanged: (Bool) -> Void

    var body: some View {
        Slider(progress: $progress)
            .gestureBehavior(.thumb)
            .rate { pointOffset in
                if abs(pointOffset.y) > 50 {
                    return 0.01
                } else {
                    return 1
                }
            }
            .onEditingChanged { isEditing in
                self.isEditing = isEditing
                onEditingChanged(isEditing)
            }
            .track { _, _ in
                Color.purple
                    .frame(height: 5)
                    .clipShape(Capsule())
            }
            .trackBackground { _, _ in
                Color.gray
                    .opacity(0.5)
                    .frame(height: 5)
                    .clipShape(Capsule())
            }
            .thumb { isEditing, _ in
                ZStack {
                    Color.clear

                    Circle()
                        .foregroundColor(Color.purple)
                        .frame(width: isEditing ? 25 : 20)
                }
                .frame(width: 50, height: 50)
            }
            .frame(height: 50)
            .padding()
            .animation(.linear(duration: 0.2), value: isEditing)
    }
}

extension ThumbSlider {

    init(progress: Binding<CGFloat>) {
        self._progress = progress
        self.onEditingChanged = { _ in }
    }

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }
}
