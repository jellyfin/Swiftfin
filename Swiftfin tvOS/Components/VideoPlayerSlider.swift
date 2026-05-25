//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct VideoPlayerSlider<Value: BinaryFloatingPoint>: View {

    @Binding
    private var value: Value

    private let currentProgress: Value?
    private let total: Value
    private let isScrollingEnabled: Bool
    private var onEditingChanged: (Bool) -> Void

    init(
        value: Binding<Value>,
        currentProgress: Value?,
        total: Value,
        isScrollingEnabled: Bool = true
    ) {
        self._value = value
        self.currentProgress = currentProgress
        self.total = total
        self.isScrollingEnabled = isScrollingEnabled
        self.onEditingChanged = { _ in }
    }

    var body: some View {
        SliderContainer(
            value: $value,
            total: total,
            isScrollingEnabled: isScrollingEnabled,
            originProgress: currentProgress,
            onEditingChanged: onEditingChanged
        ) {
            VideoPlayerSliderContent()
        }
    }
}

extension VideoPlayerSlider {

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }
}

private struct VideoPlayerSliderContent: SliderContentView {

    @Environment(\.isEnabled)
    private var isEnabled

    @EnvironmentObject
    private var containerState: VideoPlayerContainerState
    @EnvironmentObject
    var sliderState: SliderContainerState<Double>

    private let tickWidth: CGFloat = 3

    private var activeColor: Color {
        isEnabled ? .white : .lightGray
    }

    private var scrubbedProgress: Double {
        progress(for: sliderState.value)
    }

    private var currentProgress: Double? {
        sliderState.originValue.map(progress(for:))
    }

    private var committedProgress: Double {
        guard let currentProgress else {
            return scrubbedProgress
        }

        return min(scrubbedProgress, currentProgress)
    }

    private var pendingProgress: Double? {
        guard let currentProgress else {
            return nil
        }

        return max(scrubbedProgress, currentProgress)
    }

    private var shouldShowCurrentTick: Bool {
        guard let currentProgress else {
            return false
        }

        return abs(currentProgress - scrubbedProgress) > 0.001
    }

    private func progress(for value: Double) -> Double {
        guard sliderState.total > 0 else {
            return 0
        }

        return clamp(value / sliderState.total, min: 0, max: 1)
    }

    @ViewBuilder
    private func progressSegment(progress: Double, in size: CGSize) -> some View {
        Rectangle()
            .frame(width: size.width * progress + size.height)
            .offset(x: -size.height)
    }

    private func tickOffset(for progress: Double, in width: CGFloat) -> CGFloat {
        clamp(width * progress - tickWidth / 2, min: 0, max: width - tickWidth)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(activeColor.opacity(0.2))

                if let pendingProgress {
                    progressSegment(progress: pendingProgress, in: proxy.size)
                        .foregroundStyle(activeColor.opacity(0.45))
                }

                progressSegment(progress: committedProgress, in: proxy.size)
                    .foregroundStyle(activeColor)

                if shouldShowCurrentTick, let currentProgress {
                    Rectangle()
                        .fill(activeColor.opacity(0.95))
                        .frame(width: tickWidth)
                        .offset(x: tickOffset(for: currentProgress, in: proxy.size.width))
                }
            }
            .clipShape(Capsule())
        }
        .onChange(of: sliderState.isFocused) { _, focused in
            if !focused {
                containerState.cancelScrub()
            }
        }
        .opacity(sliderState.isFocused ? 1 : 0.7)
        .animation(.linear(duration: 0.1), value: sliderState.value)
        .animation(.easeInOut(duration: 0.2), value: sliderState.isFocused)
        .animation(.easeInOut(duration: 0.2), value: sliderState.originValue != nil)
    }
}
