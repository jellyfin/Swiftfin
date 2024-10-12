//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: support `total` handling

struct CapsuleSlider: View {

    @Binding
    private var value: Double
    
    @State
    private var contentSize: CGSize = .zero
    @State
    private var isEditing: Bool = false
    @State
    private var dragStartProgress: Double = 0
    @State
    private var currentTranslationStartLocation: CGPoint = .zero
    @State
    private var currentTranslation: CGFloat = 0
    
    private var onEditingChanged: (Bool) -> Void
    
    private var trackDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { newValue in
                if !isEditing {
                    isEditing = true
                    onEditingChanged(true)
                    dragStartProgress = self.value
                    currentTranslationStartLocation = newValue.location
                    currentTranslation = 0
                }

                currentTranslation = currentTranslationStartLocation.x - newValue.location.x

                let newProgress = dragStartProgress - currentTranslation / contentSize.width
                self.value = min(max(0, newProgress), 1)
            }
            .onEnded { _ in
                isEditing = false
                onEditingChanged(false)
            }
    }

    var body: some View {
        ProgressView(value: value)
            .progressViewStyle(.playback)
            .overlay {
                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(trackDrag)
            }
            .trackingSize($contentSize)
    }
}

extension CapsuleSlider {

    init(value: Binding<Double>) {
        self.init(
            value: value,
            onEditingChanged: { _ in }
        )
    }
    
    func onEditingChanged(perform action: @escaping (Bool) -> Void) -> Self {
        copy(modifying: \.onEditingChanged, with: action)
    }
}

struct Test: View {
    
    @State
    private var value = 0.1
    
    @State
    private var isEditing = false
    
    var body: some View {
        CapsuleSlider(value: $value)
            .onEditingChanged { newValue in
                isEditing = newValue
            }
            .scaleEffect(isEditing ? 1.1 : 1)
            .animation(.snappy(duration: 0.3), value: isEditing)
    }
}

struct CapsuleSlider_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            
            Test()
                .frame(height: 30)
        }
        .padding(.horizontal, 10)
        .previewInterfaceOrientation(.landscapeRight)
    }
}
