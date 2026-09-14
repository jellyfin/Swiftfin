//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleSliderStyle: SliderContainerStyle {

    var showsProgressWhenUnfocused = true

    func makeBody(configuration: SliderContainerStyleConfiguration) -> some View {
        let progress = configuration.progress
        let origin = configuration.originProgress
        let committedProgress = min(progress, origin ?? progress)
        let pendingProgress = origin.map { max(progress, $0) }
        let tickProgress = origin.flatMap { abs($0 - progress) > 0.001 ? $0 : nil }
            ?? (!showsProgressWhenUnfocused && !configuration.isFocused ? progress : nil)

        ProgressView(value: committedProgress, total: 1)
            .progressViewStyle(CapsuleProgressViewStyle(
                secondaryProgress: pendingProgress,
                cornerStyle: .round,
                tickProgress: tickProgress,
                showsProgress: showsProgressWhenUnfocused || configuration.isFocused
            ))
            #if os(tvOS)
            .opacity(configuration.isFocused ? 1 : 0.7)
            .animation(.easeInOut(duration: 0.2), value: configuration.isFocused)
            .animation(.easeInOut(duration: 0.2), value: configuration.originValue != nil)
            #endif
    }
}

extension SliderContainerStyle where Self == CapsuleSliderStyle {

    static var capsule: CapsuleSliderStyle {
        CapsuleSliderStyle()
    }

    static func capsule(showsProgressWhenUnfocused: Bool) -> CapsuleSliderStyle {
        CapsuleSliderStyle(showsProgressWhenUnfocused: showsProgressWhenUnfocused)
    }
}
