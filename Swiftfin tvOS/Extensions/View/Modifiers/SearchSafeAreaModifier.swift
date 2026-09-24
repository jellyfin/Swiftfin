//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
import UIKit

/// Native search has its own safe area, independent of the results' SwiftUI padding.
struct SearchSafeAreaModifier: ViewModifier {

    @Environment(\.tabSafeAreaInsets)
    private var tabSafeAreaInsets

    @State
    private var adjustment = SearchSafeAreaAdjustment()

    func body(content: Content) -> some View {
        content
            .introspect(SearchContainerType(), on: .tvOS(.v26...)) { container in
                adjustment.apply(to: container, topInset: tabSafeAreaInsets.top)
            }
            .onDisappear {
                adjustment.reset()
            }
    }
}

private struct SearchContainerType: IntrospectableViewType {}

private extension tvOSViewVersion<SearchContainerType, UISearchContainerViewController> {
    static let v26 = Self(for: .v26)
}

@MainActor
private final class SearchSafeAreaAdjustment {

    private weak var controller: UISearchController?
    private var originalTopInset: CGFloat = 0

    func apply(to container: UISearchContainerViewController, topInset: CGFloat) {
        let controller = container.searchController
        if self.controller !== controller {
            reset()
            self.controller = controller
            originalTopInset = controller.additionalSafeAreaInsets.top
        }

        // Measure the parent so our adjustment never feeds back into the next
        // measurement. Native search already consumes this inset for a top tab bar.
        let additionalTopInset = max(originalTopInset, topInset - container.view.safeAreaInsets.top)
        if controller.additionalSafeAreaInsets.top != additionalTopInset {
            controller.additionalSafeAreaInsets.top = additionalTopInset
        }
    }

    func reset() {
        controller?.additionalSafeAreaInsets.top = originalTopInset
        controller = nil
    }
}
