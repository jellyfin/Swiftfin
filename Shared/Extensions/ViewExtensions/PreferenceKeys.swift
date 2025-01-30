//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FramePreferenceKey: PreferenceKey {

    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {}
}

struct GeometryPrefenceKey: PreferenceKey {

    struct Value: Equatable {
        let size: CGSize
        let safeAreaInsets: EdgeInsets
    }

    static var defaultValue: Value = Value(size: .zero, safeAreaInsets: .init(top: 0, leading: 0, bottom: 0, trailing: 0))
    static func reduce(value: inout Value, nextValue: () -> Value) {}
}

struct LocationPreferenceKey: PreferenceKey {

    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}
