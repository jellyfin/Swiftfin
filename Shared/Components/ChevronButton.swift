//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ChevronButton<Icon: View>: View {

    private let icon: Icon
    private let isExternal: Bool
    private let title: Text
    private let subtitle: Text?
    private var onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {

                icon
                    .font(.body.weight(.bold))

                title

                Spacer()

                if let subtitle {
                    subtitle
                        .foregroundStyle(.secondary)
                }

                Image(systemName: isExternal ? "arrow.up.forward" : "chevron.right")
                    .font(.body.weight(.regular))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.primary, .secondary)
    }
}

extension ChevronButton where Icon == EmptyView {

    init(
        _ title: String,
        subtitle: String? = nil,
        external: Bool = false
    ) {
        self.init(
            icon: EmptyView(),
            isExternal: external,
            title: Text(title),
            subtitle: {
                if let subtitle {
                    Text(subtitle)
                } else {
                    nil
                }
            }(),
            onSelect: {}
        )
    }

    init(
        _ title: String,
        subtitle: Text?,
        external: Bool = false
    ) {
        self.init(
            icon: EmptyView(),
            isExternal: external,
            title: Text(title),
            subtitle: subtitle,
            onSelect: {}
        )
    }
}

extension ChevronButton where Icon == Image {

    init(
        _ title: String,
        subtitle: String? = nil,
        systemName: String,
        external: Bool = false
    ) {
        self.init(
            icon: Image(systemName: systemName),
            isExternal: external,
            title: Text(title),
            subtitle: {
                if let subtitle {
                    Text(subtitle)
                } else {
                    nil
                }
            }(),
            onSelect: {}
        )
    }

    init(
        _ title: String,
        subtitle: Text?,
        systemName: String,
        external: Bool = false
    ) {
        self.init(
            icon: Image(systemName: systemName),
            isExternal: external,
            title: Text(title),
            subtitle: subtitle,
            onSelect: {}
        )
    }

    init(
        _ title: String,
        subtitle: String? = nil,
        image: Image,
        external: Bool = false
    ) {
        self.init(
            icon: image,
            isExternal: external,
            title: Text(title),
            subtitle: {
                if let subtitle {
                    Text(subtitle)
                } else {
                    nil
                }
            }(),
            onSelect: {}
        )
    }

    init(
        _ title: String,
        subtitle: Text?,
        image: Image,
        external: Bool = false
    ) {
        self.init(
            icon: image,
            isExternal: external,
            title: Text(title),
            subtitle: subtitle,
            onSelect: {}
        )
    }
}

extension ChevronButton {

    func onSelect(perform action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
