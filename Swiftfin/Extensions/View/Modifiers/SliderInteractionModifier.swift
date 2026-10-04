//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: change "damping" behavior
//       - change to be based on given stride of `Value`
//         to translation diff step

struct SliderInteractionModifier<Value: BinaryFloatingPoint>: ViewModifier {

    @Binding
    var value: Value

    @State
    private var contentSize: CGSize = .zero
    @State
    private var gestureTranslation: CGPoint = .zero
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

    let total: Value
    let isScrollingEnabled: Bool
    let isEditing: Bool
    let translationBinding: Binding<CGPoint>
    let valueDamping: Double
    let gesturePadding: CGFloat
    let onEditingChanged: (Bool) -> Void

    private var gestureHeight: CGFloat {
        guard contentSize.height.isFinite else { return 0 }

        let height = contentSize.height + gesturePadding
        guard height.isFinite else { return 0 }

        return max(0, height)
    }

    private var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { newValue in
                guard isScrollingEnabled,
                      contentSize.width.isFinite,
                      contentSize.width > 0,
                      newValue.location.x.isFinite,
                      newValue.location.y.isFinite
                else {
                    return
                }

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

                guard newTranslation.x.isFinite,
                      newTranslation.y.isFinite,
                      currentValueDampingStartValue.isFinite
                else {
                    return
                }

                let newProgress = currentValueDampingStartValue - Value(newTranslation.x / contentSize.width) * total
                guard newProgress.isFinite else { return }

                value = clamp(newProgress, min: 0, max: total)
            }
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                Color.clear
                    .allowsHitTesting(isScrollingEnabled)
                    .frame(height: gestureHeight)
                    .contentShape(Rectangle())
                    .highPriorityGesture(dragGesture)
                    .onLongPressGesture(minimumDuration: 0.01, perform: {}) { isPressing in
                        if isPressing {
                            guard isScrollingEnabled else { return }
                            onEditingChanged(true)
                            needsToSetTranslationStartState = true
                        } else {
                            onEditingChanged(false)
                        }
                    }
            }
            .trackingSize($contentSize)
            .onChange(of: value) {
                let newValue = value
                guard isEditing else { return }

                if newValue == 0 || newValue == total {
                    UIDevice.impact(.light)
                }
            }
            .onChange(of: gestureTranslation) {
                if isEditing {
                    translationBinding.wrappedValue = gestureTranslation
                }
            }
            .onChange(of: isEditing) {
                if !isEditing {
                    translationBinding.wrappedValue = .zero
                    needsToSetTranslationStartState = true
                }
            }
    }
}
