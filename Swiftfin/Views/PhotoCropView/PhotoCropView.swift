//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Mantis
import SwiftUI

struct PhotoCropView<Item>: View {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject
    var viewModel: ImageViewModel<Item>

    @StateObject
    private var proxy: _PhotoCropView.Proxy = .init()

    let image: UIImage
    let cropShape: Mantis.CropShapeType
    let presetRatio: Mantis.PresetFixedRatioType

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
            proxy: proxy,
            onImageCropped: { cropped in
                viewModel.upload(cropped)
            },
            onCropFailed: {}
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(L10n.rotate, systemImage: "rotate.right") {
                    proxy.rotate()
                }
                .foregroundStyle(Color.accentColor)
            }
            if showsRatioPresets {
                ToolbarItem(placement: .bottomBar) {
                    HStack(spacing: 8) {
                        ForEach(AspectRatios.allCases) { preset in
                            Button(preset.displayTitle) {
                                proxy.setAspectRatio(preset.ratio)
                            }
                            .isSelected(proxy.selectedRatio == preset.ratio)
                            .buttonStyle(.toolbarCapsule)
                        }
                    }
                    .scrollIfLargerThanContainer(axes: .horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarCloseButton {
            dismiss()
        }
        .topBarTrailing {
            if proxy.hasChanges {
                Button(L10n.reset) {
                    proxy.reset()
                }
                .buttonStyle(.toolbarPill(.red))
            }

            Button(L10n.save) {
                proxy.crop()
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.background.is(.updating))
            .opacity(viewModel.background.is(.updating) ? 0.5 : 1)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                dismiss()
            case .deleted:
                break
            }
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .bottomBar)
    }
}

// MARK: - Controller View

private struct _PhotoCropView: UIViewControllerRepresentable {

    class Proxy: ObservableObject {

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
    }

    let initialImage: UIImage
    let cropShape: Mantis.CropShapeType
    let presetRatio: Mantis.PresetFixedRatioType
    let proxy: Proxy
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
        context.coordinator.proxy = proxy
        proxy.cropViewController = cropViewController

        return cropViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: CropViewControllerDelegate {

        var onImageCropped: ((UIImage) -> Void)?
        var onCropFailed: (() -> Void)?
        weak var proxy: Proxy?

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
            proxy?.hasChanges = true
        }
    }
}
