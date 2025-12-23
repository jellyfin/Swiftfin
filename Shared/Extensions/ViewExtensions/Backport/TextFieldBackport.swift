//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - TextField/SecureField Backports for tvOS

// Workaround for tvOS TextField/SecureField label issue
// https://forums.developer.apple.com/forums/thread/739545
// On tvOS < 18, using TextField/SecureField with labels in alerts would crash or misbehave.
// This provides a version-aware wrapper that restores proper labels on tvOS 18+.

extension Backport where Content == Never {

    @ViewBuilder
    static func textField(_ title: String, text: Binding<String>) -> some View {
        #if os(tvOS)
        if #available(tvOS 18.0, *) {
            TextField(title, text: text)
        } else {
            TextField(text: text) {}
        }
        #else
        TextField(title, text: text)
        #endif
    }

    @ViewBuilder
    static func secureField(_ title: String, text: Binding<String>) -> some View {
        #if os(tvOS)
        if #available(tvOS 18.0, *) {
            SecureField(title, text: text)
        } else {
            SecureField(text: text) {}
        }
        #else
        SecureField(title, text: text)
        #endif
    }
}
