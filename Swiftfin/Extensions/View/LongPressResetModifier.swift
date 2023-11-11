//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LongPressResetModifier<Value>: ViewModifier {
    
    let binding: Binding<Value>
    let toValue: Value
    
    @State
    private var flashing = false
    
    func body(content: Content) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onLongPressGesture {
                    binding.wrappedValue = toValue
                    
                    flashing = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.flashing = false
                    }
                }
            
            content
        }
        .listRowBackground(
            Color(flashing ? UIColor.secondarySystemBackground : UIColor.systemBackground)
                .animation(.linear(duration: flashing ? 0.2 : 0.4), value: flashing)
        )
    }
}
