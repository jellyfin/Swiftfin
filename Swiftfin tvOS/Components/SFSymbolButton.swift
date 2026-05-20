//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct SFSymbolButton: UIViewRepresentable {

    private let action: () -> Void
    private let pointSize: CGFloat
    private let systemName: String
    private let systemNameFocused: String?

    private func makeButtonConfig(_ button: UIButton) {
        let symbolImageConfig = UIImage.SymbolConfiguration(pointSize: pointSize)
        let symbolImage = UIImage(systemName: systemName, withConfiguration: symbolImageConfig)

        button.setImage(symbolImage, for: .normal)

        if let systemNameFocused {
            let focusedSymbolImage = UIImage(systemName: systemNameFocused, withConfiguration: symbolImageConfig)

            button.setImage(focusedSymbolImage, for: .focused)
        }
    }

    func makeUIView(context: Context) -> some UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.cornerStyle = .capsule

        let buttonAction = UIAction(title: "") { _ in
            self.action()
        }

        let button = UIButton(configuration: configuration, primaryAction: buttonAction)

        makeButtonConfig(button)

        return button
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        makeButtonConfig(uiView)
    }
}

extension SFSymbolButton {

    init(
        systemName: String,
        systemNameFocused: String? = nil,
        pointSize: CGFloat = 32,
        action: @escaping () -> Void = {}
    ) {
        self.init(
            action: action,
            pointSize: pointSize,
            systemName: systemName,
            systemNameFocused: systemNameFocused
        )
    }
}
