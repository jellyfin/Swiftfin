//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FullScreenMenu: View {

    // MARK: - Menu Contents

    private var title: String?
    private var subtitle: String?
    private var contentView: () -> any View
    private var footerView: () -> any View

    // MARK: - Menu Orientation

    private var orientation: FullScreenMenu.Orientation

    // MARK: - Body

    var body: some View {
        ZStack(alignment: orientation.alignment) {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            menuView
                .padding(0)
        }
    }

    // MARK: - Menu View

    @ViewBuilder
    private var menuView: some View {
        VStack {
            VStack(spacing: 4) {
                if let title {
                    Text(title)
                        .font(.headline)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                }
            }

            contentView()
                .eraseToAnyView()
                .frame(maxWidth: .infinity)
                .padding(16)

            footerView()
                .eraseToAnyView()
                .frame(maxWidth: .infinity)
                .padding(16)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 50)
                .fill(orientation.fill)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.black.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .frame(
            minWidth: orientation.minWidth,
            maxWidth: orientation.maxWidth,
            minHeight: orientation.minHeight,
            maxHeight: orientation.maxHeight
        )
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Overlay Orientation

    enum Orientation {
        case leading
        case center
        case trailing

        // MARK: - Orientation Alignment

        var alignment: Alignment {
            switch self {
            case .leading:
                .leading
            case .center:
                .center
            case .trailing:
                .trailing
            }
        }

        // MARK: - Orientation Alignment

        var fill: Material {
            switch self {
            case .leading, .trailing:
                Material.thick
            case .center:
                Material.thin
            }
        }

        // MARK: - Orientation Minimum Width

        var minWidth: CGFloat {
            UIScreen.main.bounds.width * 0.25
        }

        // MARK: - Orientation Maximum Width

        var maxWidth: CGFloat {
            switch self {
            case .leading, .trailing:
                return UIScreen.main.bounds.width * 0.275
            case .center:
                return UIScreen.main.bounds.width * 0.4
            }
        }

        // MARK: - Orientation Minimum Height

        var minHeight: CGFloat {
            switch self {
            case .leading, .trailing:
                return UIScreen.main.bounds.height * 0.9
            case .center:
                return UIScreen.main.bounds.height * 0.4
            }
        }

        // MARK: - Orientation Maximum Height

        var maxHeight: CGFloat {
            UIScreen.main.bounds.height * 0.9
        }
    }
}

extension FullScreenMenu {

    init(_ title: String? = nil, subtitle: String? = nil, orientation: FullScreenMenu.Orientation = .center) {
        self.init(
            title: title,
            subtitle: subtitle,
            contentView: { EmptyView() },
            footerView: { EmptyView() },
            orientation: orientation
        )
    }

    func contentView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.contentView, with: content)
    }

    func footerView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.footerView, with: content)
    }
}
