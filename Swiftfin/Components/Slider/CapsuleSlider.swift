//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: change "damping" behavior
//       - change to be based on given stride of `Value`
//         to translation diff step

struct CapsuleSlider<Value: BinaryFloatingPoint>: View {

    @Binding
    private var value: Value

    @State
    private var contentSize: CGSize = .zero
    @State
    private var gestureTranslation: CGPoint = .zero
    @State
    private var isEditing: Bool = false
    @State
    private var translationStartLocation: CGPoint = .zero

    @State
    private var currentValueDampingStartTranslation: CGPoint = .zero
    @State
    private var currentValueDamping: Double = 1.0
    @State
    private var currentValueDampingStartValue: Value = .zero

    @State
    private var needsToSetTranslationStartState: Bool = true

    private var gesturePadding: CGFloat
    private var onEditingChanged: (Bool) -> Void
    private let total: Value
    private let translationBinding: Binding<CGPoint>
    private let valueDamping: Double

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { newValue in
                if needsToSetTranslationStartState {
                    translationStartLocation = newValue.location
                    needsToSetTranslationStartState = false

                    currentValueDamping = valueDamping
                    currentValueDampingStartTranslation = newValue.location
                    currentValueDampingStartValue = value
                }

                if valueDamping != currentValueDamping {
                    currentValueDamping = valueDamping
                    currentValueDampingStartTranslation = newValue.location
                    currentValueDampingStartValue = value
                }

                gestureTranslation = CGPoint(
                    x: translationStartLocation.x - newValue.location.x,
                    y: translationStartLocation.y - newValue.location.y
                )

                let newTranslation = CGPoint(
                    x: (currentValueDampingStartTranslation.x - newValue.location.x) * currentValueDamping,
                    y: currentValueDampingStartTranslation.y - newValue.location.y
                )

                let newProgress = currentValueDampingStartValue - Value(newTranslation.x / contentSize.width) * total
                value = clamp(newProgress, min: 0, max: total)
            }
    }

    var body: some View {
        ProgressView(value: value, total: total)
            .progressViewStyle(.playback)
            .overlay {
                Color.clear
                    .frame(height: contentSize.height + gesturePadding)
                    .contentShape(Rectangle())
                    .highPriorityGesture(dragGesture)
                    .onLongPressGesture(minimumDuration: 0.01, perform: {}) { isPressing in
                        if isPressing {
                            isEditing = true
                            onEditingChanged(true)
                            needsToSetTranslationStartState = true
                        } else {
                            translationBinding.wrappedValue = .zero
                            isEditing = false
                            onEditingChanged(false)
                        }
                    }
            }
            .trackingSize($contentSize)
            .onChange(of: value) { newValue in
                guard isEditing else { return }

                if newValue == 0 || newValue == total {
                    UIDevice.impact(.light)
                }
            }
            .onChange(of: gestureTranslation) { newValue in
                if isEditing {
                    translationBinding.wrappedValue = newValue
                }
            }
    }
}

extension CapsuleSlider {

    init(
        value: Binding<Value>,
        total: Value = 1.0,
        valueDamping: Double = 1.0
    ) {
        self.init(
            value: value,
            total: total,
            translation: .constant(.zero),
            valueDamping: valueDamping
        )
    }

    init(
        value: Binding<Value>,
        total: Value = 1.0,
        translation: Binding<CGPoint>,
        valueDamping: Double = 1.0
    ) {
        self._value = value
        self.gesturePadding = 0
        self.onEditingChanged = { _ in }
        self.total = total
        self.translationBinding = translation
        self.valueDamping = clamp(valueDamping, min: 0.01, max: 2)
    }

    func onEditingChanged(perform action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }

    func gesturePadding(_ padding: CGFloat) -> Self {
        copy(modifying: \.gesturePadding, with: padding)
    }
}
