//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct Backport<Content> {

    let content: Content
}

extension Backport where Content: View {

    /// Note: has no effect on iOS/tvOS 15
    @ViewBuilder
    func fontWeight(_ weight: Font.Weight?) -> some View {
        if #available(iOS 16, tvOS 16, *) {
            content.fontWeight(weight)
        } else {
            content
        }
    }

    @ViewBuilder
    func lineLimit(_ limit: Int, reservesSpace: Bool = false) -> some View {
        if #available(iOS 16, tvOS 16, *) {
            content
                .lineLimit(limit, reservesSpace: reservesSpace)
        } else {
            // This may still not be enough and will probably have to
            // use String.height in a frame as caller site
            //
            // The `.font` modifier must come after this modifier in
            // order for the layout and content fonts to match
            ZStack(alignment: .top) {
                if reservesSpace {
                    Text("A" + String(repeating: "A\nA", count: limit - 1))
                        .hidden()
                }

                content
                    .lineLimit(limit)
            }
        }
    }

    @ViewBuilder
    func scrollDisabled(_ disabled: Bool) -> some View {
        if #available(iOS 16, tvOS 16, *) {
            content.scrollDisabled(disabled)
        } else {
            content.introspect(.scrollView, on: .iOS(.v15), .tvOS(.v15)) { scrollView in
                scrollView.isScrollEnabled = !disabled
            }
        }
    }

    @ViewBuilder
    func scrollIndicators(_ visibility: Backport.ScrollIndicatorVisibility) -> some View {
        if #available(iOS 16, tvOS 16, *) {
            content.scrollIndicators(visibility.supportedValue)
        } else {
            content.introspect(.scrollView, on: .iOS(.v15), .tvOS(.v15)) { scrollView in
                scrollView.showsHorizontalScrollIndicator = visibility == .visible
                scrollView.showsVerticalScrollIndicator = visibility == .visible
            }
        }
    }

    #if os(iOS)

    // TODO: - remove comment when migrated away from Stinsen
    //
    // This doesn't seem to work on device, but does in the simulator.
    // It is assumed that because Stinsen adds a lot of views that the
    // PreferencesView isn't in the right place in the VC chain so that
    // it can apply the settings, even SwiftUI's deferment.
    @available(iOS 15.0, *)
    @ViewBuilder
    func defersSystemGestures(on edges: Edge.Set) -> some View {
        if #available(iOS 16, *) {
            content
                .defersSystemGestures(on: edges)
        } else {
            content
                .preferredScreenEdgesDeferringSystemGestures(edges.asUIRectEdge)
        }
    }

    @ViewBuilder
    func persistentSystemOverlays(_ visibility: Visibility) -> some View {
        if #available(iOS 16, *) {
            content
                .persistentSystemOverlays(visibility)
        } else {
            content
                .prefersHomeIndicatorAutoHidden(visibility == .hidden ? true : false)
        }
    }
    #endif
}

// MARK: ButtonBorderShape

extension ButtonBorderShape {

    static let circleBackport: ButtonBorderShape = {
        if #available(iOS 17, *) {
            return ButtonBorderShape.circle
        } else {
            return ButtonBorderShape.roundedRectangle
        }
    }()
}
