//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

// https://github.com/SwapnanilDhol/SUIFontPicker
public struct FontPicker: UIViewControllerRepresentable {

    @Environment(\.dismiss)
    private var dismiss
    private let onFontPick: (UIFontDescriptor) -> Void

    public init(onFontPick: @escaping (UIFontDescriptor) -> Void) {
        self.onFontPick = onFontPick
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<FontPicker>) -> UIFontPickerViewController {
        let configuration = UIFontPickerViewController.Configuration()
        configuration.includeFaces = true

        let vc = UIFontPickerViewController(configuration: configuration)
        vc.delegate = context.coordinator
        return vc
    }

    public func makeCoordinator() -> FontPicker.Coordinator {
        Coordinator(self, onFontPick: self.onFontPick)
    }

    public class Coordinator: NSObject, UIFontPickerViewControllerDelegate {

        var parent: FontPicker
        private let onFontPick: (UIFontDescriptor) -> Void

        init(_ parent: FontPicker, onFontPick: @escaping (UIFontDescriptor) -> Void) {
            self.parent = parent
            self.onFontPick = onFontPick
        }

        public func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
            guard let descriptor = viewController.selectedFontDescriptor else { return }
            onFontPick(descriptor)
            parent.dismiss()
        }

        public func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) {
            parent.dismiss()
        }
    }

    public func updateUIViewController(
        _ uiViewController: UIFontPickerViewController,
        context: UIViewControllerRepresentableContext<FontPicker>
    ) {}
}
