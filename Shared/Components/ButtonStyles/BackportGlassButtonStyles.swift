//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension BackportButtonStyle where Self == BackportGlassButtonStyle {

    static var glass: Self {
        BackportGlassButtonStyle()
    }
}

extension BackportButtonStyle where Self == BackportGlassProminentButtonStyle {

    static var glassProminent: Self {
        BackportGlassProminentButtonStyle()
    }
}

struct BackportGlassButtonStyle: BackportButtonStyle {

    private var legacyGlass = BackportGlass.regular

    func shadow(_ isEnabled: Bool = true) -> Self {
        var copy = self
        copy.legacyGlass = legacyGlass.shadow(isEnabled)
        return copy
    }

    func makeBody(configuration: Configuration) -> some View {
        BackportGlassButtonStyleBody(
            configuration: configuration,
            legacyGlass: legacyGlass,
            prominence: .standard
        )
    }
}

struct BackportGlassProminentButtonStyle: BackportButtonStyle {

    private var legacyGlass = BackportGlass.regular

    func shadow(_ isEnabled: Bool = true) -> Self {
        var copy = self
        copy.legacyGlass = legacyGlass.shadow(isEnabled)
        return copy
    }

    func makeBody(configuration: Configuration) -> some View {
        BackportGlassButtonStyleBody(
            configuration: configuration,
            legacyGlass: legacyGlass,
            prominence: .prominent
        )
    }
}

private struct BackportGlassButtonStyleBody: View {

    enum Prominence {
        case standard
        case prominent
    }

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled

    @Environment(\.controlSize)
    private var controlSize

    @Environment(\.isEnabled)
    private var isEnabled

    let configuration: PrimitiveButtonStyleConfiguration
    let legacyGlass: BackportGlass
    let prominence: Prominence

    @ViewBuilder
    var body: some View {
        #if os(tvOS)
        if #available(tvOS 26.0, *), isLiquidGlassEnabled {
            nativeBody
        } else {
            fallbackBody
        }
        #else
        if #available(iOS 26.0, *), isLiquidGlassEnabled {
            nativeBody
        } else {
            fallbackBody
        }
        #endif
    }

    @available(iOS 26.0, tvOS 26.0, *)
    @ViewBuilder
    private var nativeBody: some View {
        switch prominence {
        case .standard:
            nativeButton
                .buttonStyle(.glass)
        case .prominent:
            nativeButton
                .buttonStyle(.glassProminent)
        }
    }

    private var nativeButton: some View {
        Button(role: configuration.role) {
            configuration.trigger()
        } label: {
            configuration.label
        }
    }

    @ViewBuilder
    private var fallbackBody: some View {
        switch prominence {
        case .standard:
            fallbackButton
                .backport
                .glassEffect(legacyGlass, in: .capsule)
        case .prominent:
            fallbackButton
                .backport
                .glassEffect(
                    legacyGlass.selection(
                        tint: prominentTint,
                        foregroundColor: prominentTint.overlayColor
                    ),
                    in: .capsule
                )
        }
    }

    @ViewBuilder
    private var fallbackButton: some View {
        let button = Button(role: configuration.role) {
            configuration.trigger()
        } label: {
            fallbackLabel
                .padding(fallbackPadding)
        }

        #if os(tvOS)
        button
        #else
        button.buttonStyle(.borderless)
        #endif
    }

    @ViewBuilder
    private var fallbackLabel: some View {
        if isEnabled {
            configuration.label
        } else {
            configuration.label
                .foregroundStyle(.tertiary)
        }
    }

    private var fallbackPadding: EdgeInsets {
        switch controlSize {
        case .mini:
            EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8)
        case .small:
            EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
        case .regular:
            EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
        case .large:
            EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        case .extraLarge:
            EdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        @unknown default:
            EdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
        }
    }

    private var prominentTint: Color {
        switch configuration.role {
        case .destructive, .cancel:
            .red
        default:
            .accentColor
        }
    }
}
