//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Mantis
import SwiftUI

struct PhotoCropView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - State, Observed, & Environment Objects

    @StateObject
    private var proxy: _PhotoCropView.Proxy = .init()

    // MARK: - Image Variable

    let isReady: Bool
    let isSaving: Bool
    let image: UIImage
    let cropShape: Mantis.CropShapeType
    let presetRatio: Mantis.PresetFixedRatioType
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void

    // MARK: - Body

    var body: some View {
        _PhotoCropView(
            initialImage: image,
            cropShape: cropShape,
            presetRatio: presetRatio,
            proxy: proxy
        ) {
            onSave($0)
        }
        .topBarTrailing {

            if isReady {
                Button(L10n.rotate, systemImage: "rotate.right") {
                    proxy.rotate()
                }
                .foregroundStyle(.gray)
            }

            if isSaving {
                Button(L10n.cancel) {
                    onCancel()
                }
                .foregroundStyle(.red)
            } else {
                Button {
                    proxy.crop()
                } label: {
                    Text(L10n.save)
                        .foregroundStyle(accentColor.overlayColor)
                        .font(.headline)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background {
                            accentColor
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isSaving {
                    ProgressView()
                } else {
                    Button(L10n.reset) {
                        proxy.reset()
                    }
                    .foregroundStyle(.yellow)
                    .disabled(isSaving)
                }
            }
        }
        .ignoresSafeArea()
        .background {
            Color.black
        }
    }
}

// MARK: - Photo Crop View

struct _PhotoCropView: UIViewControllerRepresentable {

    class Proxy: ObservableObject {

        weak var cropViewController: CropViewController?

        func crop() {
            cropViewController?.crop()
        }

        func reset() {
            cropViewController?.didSelectReset()
        }

        func rotate() {
            cropViewController?.didSelectClockwiseRotate()
        }
    }

    let initialImage: UIImage
    let cropShape: Mantis.CropShapeType
    let presetRatio: Mantis.PresetFixedRatioType
    let proxy: Proxy
    let onImageCropped: (UIImage) -> Void

    func makeUIViewController(context: Context) -> some UIViewController {
        var config = Mantis.Config()

        config.cropViewConfig.backgroundColor = .black.withAlphaComponent(0.9)
        config.cropViewConfig.cropShapeType = cropShape
        config.presetFixedRatioType = presetRatio
        config.showAttachedCropToolbar = false

        let cropViewController = Mantis.cropViewController(
            image: initialImage,
            config: config
        )

        cropViewController.delegate = context.coordinator
        context.coordinator.onImageCropped = onImageCropped

        proxy.cropViewController = cropViewController

        return cropViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: CropViewControllerDelegate {

        var onImageCropped: ((UIImage) -> Void)?

        func cropViewControllerDidCrop(
            _ cropViewController: CropViewController,
            cropped: UIImage,
            transformation: Transformation,
            cropInfo: CropInfo
        ) {
            onImageCropped?(cropped)
        }

        func cropViewControllerDidCancel(
            _ cropViewController: CropViewController,
            original: UIImage
        ) {}

        func cropViewControllerDidFailToCrop(
            _ cropViewController: CropViewController,
            original: UIImage
        ) {}

        func cropViewControllerDidBeginResize(
            _ cropViewController: CropViewController
        ) {}

        func cropViewControllerDidEndResize(
            _ cropViewController: Mantis.CropViewController,
            original: UIImage,
            cropInfo: Mantis.CropInfo
        ) {}
    }
}
