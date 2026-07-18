//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Mantis
import SwiftUI

struct PhotoCropView: View {

    @Default(.accentColor)
    private var accentColor

    @StateObject
    private var coordinator: _PhotoCropView.Coordinator = .init()

    let isSaving: Bool
    let image: UIImage
    let cropShape: Mantis.CropShapeType
    let presetRatio: Mantis.PresetFixedRatioType
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void

    private var showsRatioPresets: Bool {
        switch presetRatio {
        case .canUseMultiplePresetFixedRatio:
            true
        case .alwaysUsingOnePresetFixedRatio:
            false
        }
    }

    var body: some View {
        _PhotoCropView(
            initialImage: image,
            cropShape: cropShape,
            presetRatio: presetRatio,
            coordinator: coordinator,
            onImageCropped: onSave,
            onCropFailed: {}
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.rotate, systemImage: "rotate.right") {
                    coordinator.rotate()
                }
                .foregroundStyle(accentColor)
            }

            // TODO: make a style for crop labels
            if showsRatioPresets {
                ToolbarItem(placement: .bottomBar) {
                    HStack(spacing: 8) {
                        ForEach(AspectRatios.allCases) { preset in
                            Button(preset.displayTitle) {
                                coordinator.setAspectRatio(preset.ratio)
                            }
                            .isSelected(coordinator.selectedRatio == preset.ratio)
                        }
                    }
                    .scrollIfLargerThanContainer(axes: .horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarCloseButton(onCancel)
        .topBarTrailing {
            if isSaving {
                ProgressView()
            }

            if coordinator.hasChanges {
                Button(L10n.reset, role: .destructive) {
                    coordinator.reset()
                }
                .backport
                .buttonStyle(.glassProminent)
                .controlSize(.small)
                .disabled(isSaving)
            }

            let saveAction: () -> Void = {
                coordinator.crop()
            }

            Group {
                if #available(iOS 26, *), Defaults[.isLiquidGlassEnabled] {
                    Button(L10n.save, role: .confirm, action: saveAction)
                } else {
                    Button(L10n.save, action: saveAction)
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                }
            }
            .disabled(isSaving)
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .bottomBar)
    }
}

// MARK: - Controller View

private struct _PhotoCropView: UIViewControllerRepresentable {

    class Coordinator: ObservableObject, CropViewControllerDelegate {

        weak var cropViewController: CropViewController?

        @Published
        var hasChanges = false

        @Published
        var selectedRatio: Double?

        func crop() {
            cropViewController?.crop()
        }

        func reset() {
            cropViewController?.didSelectReset()
            hasChanges = false
            selectedRatio = nil
        }

        func rotate() {
            cropViewController?.didSelectClockwiseRotate()
            hasChanges = true
        }

        func setAspectRatio(_ ratio: Double?) {
            if let ratio {
                cropViewController?.didSelectRatio(ratio: ratio)
            } else {
                cropViewController?.didSelectFreeRatio()
            }
            selectedRatio = ratio
            hasChanges = true
        }

        var onImageCropped: ((UIImage) -> Void)?
        var onCropFailed: (() -> Void)?

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
        ) {
            onCropFailed?()
        }

        func cropViewControllerDidBeginResize(
            _ cropViewController: CropViewController
        ) {}

        func cropViewControllerDidEndResize(
            _ cropViewController: CropViewController,
            original: UIImage,
            cropInfo: CropInfo
        ) {
            hasChanges = true
        }
    }

    let initialImage: UIImage
    let cropShape: Mantis.CropShapeType
    let presetRatio: Mantis.PresetFixedRatioType
    let coordinator: Coordinator
    let onImageCropped: (UIImage) -> Void
    let onCropFailed: () -> Void

    func makeUIViewController(context: Context) -> some UIViewController {
        var config = Mantis.Config()
        config.cropViewConfig.backgroundColor = .black.withAlphaComponent(0.9)
        config.cropViewConfig.cropShapeType = cropShape
        config.cropViewConfig.rotateCropBoxFor90DegreeRotation = false
        config.presetFixedRatioType = presetRatio
        config.showAttachedCropToolbar = false

        let cropViewController = Mantis.cropViewController(
            image: initialImage,
            config: config
        )
        cropViewController.delegate = context.coordinator
        context.coordinator.onImageCropped = onImageCropped
        context.coordinator.onCropFailed = onCropFailed
        context.coordinator.cropViewController = cropViewController

        return cropViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        coordinator
    }
}
