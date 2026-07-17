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

struct PhotoPickerModifier: ViewModifier {

    @Binding
    var isPresented: Bool

    @State
    private var selectedImage: UIImage?
    @State
    private var selectedItem: PhotosPickerItem?

    let isSaving: Bool
    let cropShape: Mantis.CropShapeType
    let presetRatio: Mantis.PresetFixedRatioType
    let onSave: (UIImage) -> Void

    func body(content: Content) -> some View {
        content
            .photosPicker(
                isPresented: $isPresented,
                selection: $selectedItem,
                matching: .images
            )
            .backport
            .onChange(of: selectedItem) { _, newValue in
                loadImage(from: newValue)
            }
            .sheet(isPresented: Binding<Bool>(
                get: { selectedImage != nil },
                set: {
                    if !$0 {
                        selectedImage = nil
                        selectedItem = nil
                    }
                }
            )) {
                if let image = selectedImage {
                    NavigationView {
                        PhotoCropView(
                            isSaving: isSaving,
                            image: image,
                            cropShape: cropShape,
                            presetRatio: presetRatio,
                            onSave: {
                                clearSelection()
                                onSave($0)
                            },
                            onCancel: clearSelection
                        )
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

    private func clearSelection() {
        selectedImage = nil
        selectedItem = nil
        isPresented = false
    }
}
