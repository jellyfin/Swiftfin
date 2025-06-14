//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CapsuleSlider<V: BinaryFloatingPoint>: View {

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

    private var gesturePadding: CGFloat = 0
    private var onEditingChanged: (Bool) -> Void
    private let total: V

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

    init(value: Binding<V>, total: V = 1.0) {
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

struct Test: View {

    @State
    private var value: Double = 50

    @State
    private var isEditing = false

    var body: some View {
        AlternateLayoutView {
            Color.clear
                .frame(height: 10)
        } content: {
            CapsuleSlider(value: $value, total: 100)
                .onEditingChanged { newValue in
                    isEditing = newValue
                }
                .gesturePadding(30)
                .frame(height: isEditing ? 20 : 10)
                .animation(.bouncy(duration: 0.3), value: isEditing)
                .onChange(of: value) { newValue in
                    print(newValue)
                }
        }
        .animation(.linear(duration: 0.05), value: value)
    }
}

struct CapsuleSlider_Previews: PreviewProvider {
    static var previews: some View {
        VStack {

            Test()
                .frame(height: 10)
        }
        .padding(.horizontal, 10)
        .previewInterfaceOrientation(.landscapeRight)
    }
}
