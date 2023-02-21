//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct SFSymbolButton: UIViewRepresentable {

    private let action: () -> Void
    private let pointSize: CGFloat
    private let systemName: String

    func makeUIView(context: Context) -> some UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.cornerStyle = .capsule

        let buttonAction = UIAction(title: "") { _ in
            self.action()
        }

        let button = UIButton(configuration: configuration, primaryAction: buttonAction)

        let symbolImageConfig = UIImage.SymbolConfiguration(pointSize: pointSize)
        let symbolImage = UIImage(systemName: systemName, withConfiguration: symbolImageConfig)

        button.setImage(symbolImage, for: .normal)

        return button
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

extension SFSymbolButton: Hashable {

    static func == (lhs: SFSymbolButton, rhs: SFSymbolButton) -> Bool {
        lhs.systemName == rhs.systemName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(systemName)
    }
}

extension SFSymbolButton {

    init(
        systemName: String,
        pointSize: CGFloat = 24,
        action: @escaping () -> Void
    ) {
        self.init(
            action: action,
            pointSize: pointSize,
            systemName: systemName
        )
    }
}
