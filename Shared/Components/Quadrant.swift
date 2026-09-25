//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct Quadrant: View {

    let corner: QuadrantCorner
    let size: CGFloat
    let cornerRadius: CGFloat
    let isFloating: Bool
    private let content: [QuadrantItem]

    init(
        _ corner: QuadrantCorner,
        size: CGFloat = UIDevice.isTV ? 45 : 25,
        cornerRadius: CGFloat = UIDevice.isTV ? 18 : 6,
        isFloating: Bool = false,
        @ArrayBuilder<QuadrantItem> content: () -> [QuadrantItem]
    ) {
        self.corner = corner
        self.size = size
        self.cornerRadius = cornerRadius
        self.isFloating = isFloating
        self.content = content()
    }

    var body: some View {
        let entries = Array(content.enumerated())
        let orderedEntries = corner.isTrailing ? Array(entries.reversed()) : entries

        HStack(spacing: 0) {
            ForEach(orderedEntries, id: \.offset) { index, item in
                Group {
                    if index == 0 {
                        // Only the anchored entry ends at its own boundary.
                        // Later backgrounds extend underneath their neighbor.
                        if isFloating {
                            item.clipShape(Capsule())
                        } else {
                            item.clipped()
                        }
                    } else {
                        item
                    }
                }
                .zIndex(Double(content.count - index))
            }
        }
        .environment(\.quadrantItemConfiguration, .init(
            size: size,
            corner: corner,
            cornerRadius: cornerRadius,
            isFloating: isFloating
        ))
        .font(.system(size: size * 0.52, weight: .semibold))
        .fixedSize()
        .allowsHitTesting(false)
    }
}

enum QuadrantCorner: CaseIterable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    fileprivate var isTrailing: Bool {
        self == .topTrailing || self == .bottomTrailing
    }

    var alignment: Alignment {
        switch self {
        case .topLeading:
            .topLeading
        case .topTrailing:
            .topTrailing
        case .bottomLeading:
            .bottomLeading
        case .bottomTrailing:
            .bottomTrailing
        }
    }
}

struct QuadrantItem: View {

    @Environment(\.quadrantItemConfiguration)
    private var configuration

    let color: Color
    private let label: Text

    init(color: Color, label: () -> Text) {
        self.color = color
        self.label = label()
    }

    var body: some View {
        label
            .fixedSize()
            .padding(.horizontal, configuration.size * 0.16)
            .frame(minWidth: configuration.size)
            .frame(height: configuration.size)
            .background {
                Group {
                    if configuration.isFloating {
                        Capsule().fill(color)
                    } else {
                        UnevenRoundedRectangle(
                            topLeadingRadius: configuration.corner == .bottomTrailing ? configuration.cornerRadius : 0,
                            bottomLeadingRadius: configuration.corner == .topTrailing ? configuration.cornerRadius : 0,
                            bottomTrailingRadius: configuration.corner == .topLeading ? configuration.cornerRadius : 0,
                            topTrailingRadius: configuration.corner == .bottomLeading ? configuration.cornerRadius : 0
                        )
                        .fill(color)
                    }
                }
                // Extend only the background under the preceding label.
                .padding(
                    configuration.corner.isTrailing ? .trailing : .leading,
                    -configuration.backgroundExtension
                )
            }
    }
}

private struct QuadrantItemConfiguration {

    var size: CGFloat = 25
    var corner: QuadrantCorner = .bottomTrailing
    var cornerRadius: CGFloat = 6
    var isFloating: Bool = false

    var backgroundExtension: CGFloat {
        isFloating ? size : min(cornerRadius, size)
    }
}

private extension EnvironmentValues {

    @Entry
    var quadrantItemConfiguration = QuadrantItemConfiguration()
}
