//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: gesture padding

struct ThumbSlider<V: BinaryFloatingPoint>: View {

    @Binding
    private var value: V

    @State
    private var contentSize: CGSize = .zero
    @State
    private var isEditing: Bool = false
    @State
    private var translationStartLocation: CGPoint = .zero
    @State
    private var translationStartValue: V = 0
    @State
    private var currentTranslation: CGFloat = 0

    private var onEditingChanged: (Bool) -> Void
    private let total: V
    private var trackMask: () -> any View

    private var trackDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { newValue in
                if !isEditing {
                    isEditing = true
                    onEditingChanged(true)
                    translationStartValue = value
                    translationStartLocation = newValue.location
                    currentTranslation = 0
                }

                currentTranslation = translationStartLocation.x - newValue.location.x

                let newProgress = translationStartValue - V(currentTranslation / contentSize.width) * total
                value = clamp(newProgress, min: 0, max: total)
            }
            .onEnded { _ in
                isEditing = false
                onEditingChanged(false)
            }
    }

    var body: some View {
        ProgressView(value: value, total: total)
            .progressViewStyle(.playback.square)
            .overlay(alignment: .leading) {
                Circle()
                    .foregroundStyle(.primary)
                    .frame(height: 20)
                    .gesture(trackDrag)
                    .offset(x: Double(value / total) * contentSize.width - 10)
            }
            .trackingSize($contentSize)
    }
}

extension ThumbSlider {

    init(value: Binding<V>, total: V = 1.0) {
        self.init(
            value: value,
            onEditingChanged: { _ in },
            total: total,
            trackMask: { Color.white }
        )
    }

    func onEditingChanged(_ action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }

    func trackMask(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trackMask, with: content)
    }
}

struct ThumbSliderTests: View {

    @State
    private var value: Double = 0.3

    var body: some View {
        ThumbSlider(value: $value, total: 1.0)
            .frame(height: 5)
            .padding(.horizontal, 10)
    }
}

#Preview {
    ThumbSliderTests()
}
