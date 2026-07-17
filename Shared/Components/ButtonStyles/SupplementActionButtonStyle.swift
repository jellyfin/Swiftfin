//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension PrimitiveButtonStyle where Self == SupplementActionButtonStyle {

    static var supplementAction: SupplementActionButtonStyle {
        SupplementActionButtonStyle()
    }
}

/// Preserves the video-player supplement action appearance below OS 26 and
/// adopts interactive glass when both the SDK feature and app default are active.
struct SupplementActionButtonStyle: PrimitiveButtonStyle {

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled

    private func baseLabel(_ configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func legacyButton(_ configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            baseLabel(configuration)
                .background {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(.white)
                }
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.card)
    }

    @available(iOS 26.0, tvOS 26.0, *)
    private func glassButton(_ configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            baseLabel(configuration)
                .glassEffect(
                    .regular
                        .tint(.white)
                        .interactive(),
                    in: Capsule()
                )
        }
        .buttonBorderShape(.capsule)
    }

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        #if os(tvOS)
        if #available(tvOS 26.0, *), isLiquidGlassEnabled {
            glassButton(configuration)
        } else {
            legacyButton(configuration)
        }
        #else
        if #available(iOS 26.0, *), isLiquidGlassEnabled {
            glassButton(configuration)
        } else {
            legacyButton(configuration)
        }
        #endif
    }
}
