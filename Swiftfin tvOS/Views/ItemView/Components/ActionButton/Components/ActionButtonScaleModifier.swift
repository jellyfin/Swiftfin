//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ActionButtonScaleModifier: ViewModifier {

    // MARK: - Button Properties

    let size: CGSize

    // MARK: - Expansion Properties

    let expansion: CGFloat
    let animationDuration: Double

    // MARK: - Expansion Reason(s)

    let isFocused: Bool
    let isPressed: Bool

    // MARK: - Internal State

    @State
    private var currentScale: CGFloat = 0.0
    @State
    private var isAnimating: Bool = false
    @State
    private var animationTask: Task<Void, Never>? = nil

    // MARK: - Body

    func body(content: Content) -> some View {
        let baseSize = max(size.width, size.height)

        return content
            .scaleEffect((baseSize + (2 * currentScale)) / baseSize)
            .onChange(of: isPressed) { _, newValue in
                animationTask?.cancel()

                if newValue {
                    withAnimation(.easeInOut(duration: animationDuration / 2)) {
                        currentScale = expansion
                    }

                    animationTask = Task {
                        try? await Task.sleep(nanoseconds: UInt64(animationDuration * 0.5 * 1_000_000_000))

                        if !Task.isCancelled {
                            await MainActor.run {
                                if !isPressed {
                                    withAnimation(.easeInOut(duration: animationDuration)) {
                                        currentScale = isFocused ? expansion : 0.0
                                    }
                                }
                            }
                        }
                    }
                } else {
                    animationTask = Task {
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: animationDuration)) {
                                currentScale = isFocused ? expansion : 0.0
                            }
                        }
                    }
                }
            }
            .onChange(of: isFocused) { _, newValue in
                if !isPressed {
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        currentScale = newValue ? expansion : 0.0
                    }
                }
            }
            .onAppear {
                currentScale = isFocused ? expansion : 0.0
            }
    }
}
