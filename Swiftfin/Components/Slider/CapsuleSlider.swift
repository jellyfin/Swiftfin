//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleSlider<Value: BinaryFloatingPoint>: View {

    @Binding
    private var value: Value

    @State
    private var contentSize: CGSize = .zero
    @State
    private var isEditing: Bool = false
    @State
    private var translationStartLocation: CGPoint = .zero
    @State
    private var translationStartValue: Value = 0
    @State
    private var currentTranslation: CGFloat = 0

    private var gesturePadding: CGFloat = 0
    private var onEditingChanged: (Bool) -> Void
    private let total: Value

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

                let newProgress = translationStartValue - Value(currentTranslation / contentSize.width) * total
                value = clamp(newProgress, min: 0, max: total)
            }
            .onEnded { _ in
                isEditing = false
                onEditingChanged(false)
            }
    }

    var body: some View {
        ProgressView(value: value, total: total)
            .progressViewStyle(.playback)
            .overlay {
                Color.clear
                    .frame(height: contentSize.height + gesturePadding)
                    .contentShape(Rectangle())
                    .highPriorityGesture(trackDrag)
            }
            .trackingSize($contentSize)
            .onChange(of: value) { newValue in
                guard isEditing else { return }

                if newValue == 0 || newValue == total {
                    UIDevice.impact(.light)
                }
            }
    }
}

extension CapsuleSlider {

    init(value: Binding<Value>, total: Value = 1.0) {
        self.init(
            value: value,
            onEditingChanged: { _ in },
            total: total
        )
    }

    func onEditingChanged(perform action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }

    func gesturePadding(_ padding: CGFloat) -> Self {
        copy(modifying: \.gesturePadding, with: padding)
    }
}
