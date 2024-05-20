//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import PhotosUI
import SwiftUI

// TODO: polish: find way to deselect image on appear
//       - from popping from cropping
// TODO: polish: when image is picked, instead of loading it here
//       which takes ~1-2s, show some kind of loading indicator
//       on this view or push to another view that will go to crop

extension UserProfileImagePicker {

    struct PhotoPicker: UIViewControllerRepresentable {

        var onCancel: () -> Void
        var onSelectedImage: (UIImage) -> Void

        init(onCancel: @escaping () -> Void, onSelectedImage: @escaping (UIImage) -> Void) {
            self.onCancel = onCancel
            self.onSelectedImage = onSelectedImage
        }

        func makeUIViewController(context: Context) -> PHPickerViewController {

            var configuration = PHPickerConfiguration(photoLibrary: .shared())

            configuration.filter = .all(of: [.images, .not(.livePhotos)])
            configuration.preferredAssetRepresentationMode = .current
            configuration.selection = .ordered
            configuration.selectionLimit = 1

            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = context.coordinator

            context.coordinator.onCancel = onCancel
            context.coordinator.onSelectedImage = onSelectedImage

            return picker
        }

        func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        class Coordinator: PHPickerViewControllerDelegate {

            var onCancel: (() -> Void)?
            var onSelectedImage: ((UIImage) -> Void)?

            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {

                guard let image = results.first else {
                    onCancel?()
                    return
                }

                let itemProvider = image.itemProvider

                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        if let image = image as? UIImage {
                            self.onSelectedImage?(image)
                        }
                    }
                }
            }
        }
    }
}
