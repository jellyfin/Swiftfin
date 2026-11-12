//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Minimal app infrastructure for the shared styles. The actual capsule, label,
/// adaptive layout, glass rendering, and color implementations are compiled from Shared.
extension EnvironmentValues {

    @Entry
    var isSelected = false
    @Entry
    var frameForParentView: [CoordinateSpace: FrameAndSafeAreaInsets] = [:]
}

struct Backport<Content> {

    let content: Content
}

extension View {

    var backport: Backport<Self> {
        Backport(content: self)
    }

    @ContentBuilder
    func subtleShadow() -> some View {
        shadow(radius: 4, y: 2)
    }
}

extension Backport where Content: View {

    @ContentBuilder
    func glassEffect(_ glass: BackportGlass = .regular, in shape: some Shape) -> some View {
        content.modifier(BackportGlassEffectModifier(glass: glass, shape: shape))
    }
}

/// These names satisfy unrelated helpers in the shared layout and device files;
/// the sample has no media models or localization dependency.
enum PosterDisplayType {

    case landscape
    case portrait
    case square

    enum Size: Equatable {

        case extraSmall
        case small
        case medium
        case custom(width: CGFloat)
    }
}

enum L10n {

    static let tvOS = "tvOS"
    static let iPadOS = "iPadOS"
    static let iOS = "iOS"
}
