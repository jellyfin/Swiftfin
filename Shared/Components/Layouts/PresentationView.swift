//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol PresentationView: View {

    associatedtype StandardBody: View
    associatedtype LargeBody: View

    @ContentBuilder
    @MainActor
    var standardView: Self.StandardBody { get }
    @ContentBuilder
    @MainActor
    var largeView: Self.LargeBody { get }
}

@MainActor
extension PresentationView {

    @ContentBuilder
    var body: some View {
        PresentationContent { self.standardView } largeView: { self.largeView }
    }
}

/// Standard and large presentations share the same layout policy.
/// Size changes within either presentation are handled by AdaptiveLayout.
struct PresentationContent<StandardBody: View, LargeBody: View>: View {

    private let standardView: () -> StandardBody
    private let largeView: () -> LargeBody

    init(
        @ContentBuilder standardView: @escaping () -> StandardBody,
        @ContentBuilder largeView: @escaping () -> LargeBody
    ) {
        self.standardView = standardView
        self.largeView = largeView
    }

    @ContentBuilder
    var body: some View {
        if ViewLayout.Presentation.current == .large {
            largeView()
        } else {
            standardView()
        }
    }
}
