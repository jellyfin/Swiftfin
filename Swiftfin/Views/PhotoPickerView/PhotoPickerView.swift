//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import PhotosUI
import SwiftUI

// TODO: polish: find way to deselect image on appear
//       - from popping from cropping
// TODO: polish: when image is picked, instead of loading it here
//       which takes ~1-2s, show some kind of loading indicator
//       on this view or push to another view that will go to crop

struct PhotoPickerView: UIViewControllerRepresentable {

    // MARK: - Photo Picker Actions

    var onSelect: (UIImage) -> Void
    var onCancel: () -> Void

    // MARK: - Initializer

    init(onSelect: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.onSelect = onSelect
        self.onCancel = onCancel
    }

    // MARK: - UIView Controller

    func makeUIViewController(context: Context) -> PHPickerViewController {

        var configuration = PHPickerConfiguration(photoLibrary: .shared())

        configuration.filter = .all(of: [.images, .not(.livePhotos)])
        configuration.preferredAssetRepresentationMode = .current
        configuration.selection = .default
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator

        context.coordinator.onSelect = onSelect
        context.coordinator.onCancel = onCancel

        return picker
    }

    // MARK: - Update UIView Controller

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    // MARK: - Make Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: PHPickerViewControllerDelegate {

        var onSelect: ((UIImage) -> Void)?
        var onCancel: (() -> Void)?

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

            guard let image = results.first else {
                onCancel?()
                return
            }

            let itemProvider = image.itemProvider

            guard itemProvider.canLoadObject(ofClass: UIImage.self) else { return }

            itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                guard let image = image as? UIImage else { return }
                self.onSelect?(image)
            }
        }
    }
}
