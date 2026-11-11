//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension PrimitiveButtonStyle where Self == SupplementActionButtonStyle {

    static var supplementAction: SupplementActionButtonStyle {
        SupplementActionButtonStyle()
    }
}

struct SupplementActionButtonStyle: PrimitiveButtonStyle {

    @ContentBuilder
    private func baseLabel(_ configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.role == .destructive ? .white : .black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ContentBuilder
    private func legacyButton(_ configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            baseLabel(configuration)
                .background {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(configuration.role == .destructive ? .red : .white)
                }
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.card)
    }

    @ContentBuilder
    @available(iOS 26.0, tvOS 26.0, *)
    private func glassButton(_ configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            baseLabel(configuration)
                .glassEffect(
                    .regular
                        .tint(configuration.role == .destructive ? .red : .white)
                        .interactive(),
                    in: Capsule()
                )
        }
        .buttonBorderShape(.capsule)
        #if os(tvOS)
        .buttonStyle(.card)
        #endif
    }

    @ContentBuilder
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *), UIDevice.supportsLiquidGlass {
            glassButton(configuration)
        } else {
            legacyButton(configuration)
        }
    }
}
