//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import UIKit

struct FontPickerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIFontPickerViewController {
        let configuration = UIFontPickerViewController.Configuration()
        configuration.includeFaces = true

        let fontViewController = UIFontPickerViewController(configuration: configuration)
        fontViewController.delegate = context.coordinator
        return fontViewController
    }

    func updateUIViewController(_ uiViewController: UIFontPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIFontPickerViewControllerDelegate {
        func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
            guard let descriptor = viewController.selectedFontDescriptor else { return }
            Defaults[.subtitleFontName] = descriptor.postscriptName
        }
    }
}
