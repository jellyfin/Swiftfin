//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ButtonStyle where Self == RemoteButtonStyle {

    static var remoteControl: RemoteButtonStyle {
        RemoteButtonStyle(size: .medium)
    }

    static func remoteControl(
        size: RemoteButtonStyle.Size = .medium,
        tint: Color = .secondarySystemBackground,
        foregroundColor: Color = .primary,
        onPressed: ((Bool) -> Void)? = nil
    ) -> RemoteButtonStyle {
        RemoteButtonStyle(
            size: size,
            tint: tint,
            foregroundColor: foregroundColor,
            onPressed: onPressed
        )
    }
}

struct RemoteButtonStyle: ButtonStyle {

    enum Size {

        case small
        case medium
        case large

        var length: CGFloat {
            switch self {
            case .small:
                44
            case .medium:
                60
            case .large:
                76
            }
        }

        var font: Font {
            switch self {
            case .large:
                .title
            default:
                .title2
            }
        }
    }

    @Environment(\.isEnabled)
    private var isEnabled

    let size: Size
    var tint: Color = .secondarySystemBackground
    var foregroundColor: Color = .primary
    var onPressed: ((Bool) -> Void)?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentTransition(.symbolEffect(.replace))
            .font(size.font)
            .frame(width: size.length, height: size.length)
            .backport
            .glassEffect(
                .regular.selection(
                    tint: tint,
                    foregroundColor: foregroundColor
                ),
                in: .circle
            )
            .labelStyle(.iconOnly)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .opacity(isEnabled ? 1 : 0.5)
            .onChange(of: configuration.isPressed) { _, newValue in
                onPressed?(newValue)
            }
    }
}
