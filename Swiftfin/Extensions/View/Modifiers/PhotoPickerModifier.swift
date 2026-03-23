//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Mantis
import PhotosUI
import SwiftUI

/// SwiftUI's PhotoPicker (iOS 16+) but with Mantis Cropping built into the workflow
struct PhotoPickerModifier: ViewModifier {

    @Binding
    var isPresented: Bool

    let cropShape: Mantis.CropShapeType
    let presetRatio: Mantis.PresetFixedRatioType
    let onSelect: (UIImage) -> Void

    @State
    private var selectedItem: PhotosPickerItem?
    @State
    private var selectedImage: UIImage?

    func body(content: Content) -> some View {
        content
            .photosPicker(
                isPresented: $isPresented,
                selection: $selectedItem,
                matching: .images
            )
            .onChange(of: selectedItem) { newItem in
                loadImage(from: newItem)
            }
            .sheet(isPresented: Binding<Bool>(
                get: { selectedImage != nil },
                set: { if !$0 {
                    selectedImage = nil
                    selectedItem = nil
                } }
            )) {
                if let image = selectedImage {
                    NavigationView {
                        PhotoCropView(
                            image: image,
                            cropShape: cropShape,
                            presetRatio: presetRatio
                        ) { cropped in
                            onSelect(cropped)
                            selectedImage = nil
                            selectedItem = nil
                            isPresented = false
                        }
                    }
                }
            }
    }

    @MainActor
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else {
            selectedImage = nil
            return
        }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data)
            {
                selectedImage = image
            }
        }
    }
}
