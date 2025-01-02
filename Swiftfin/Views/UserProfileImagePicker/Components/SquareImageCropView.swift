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

extension UserProfileImagePicker {

    struct SquareImageCropView: View {

        // MARK: - Defaults

        @Default(.accentColor)
        private var accentColor

        // MARK: - State, Observed, & Environment Objects

        @EnvironmentObject
        private var router: UserProfileImageCoordinator.Router

        @StateObject
        private var proxy: _SquareImageCropView.Proxy = .init()

        @ObservedObject
        var viewModel: UserProfileImageViewModel

        // MARK: - Image Variable

        let image: UIImage

        // MARK: - Error State

        @State
        private var error: Error? = nil

        // MARK: - Body

        var body: some View {
            _SquareImageCropView(initialImage: image, proxy: proxy) {
                viewModel.send(.upload($0))
            }
            .animation(.linear(duration: 0.1), value: viewModel.state)
            .interactiveDismissDisabled(viewModel.state == .uploading)
            .navigationBarBackButtonHidden(viewModel.state == .uploading)
            .topBarTrailing {

                if viewModel.state == .initial {
                    Button(L10n.rotate, systemImage: "rotate.right") {
                        proxy.rotate()
                    }
                    .foregroundStyle(.gray)
                }

                if viewModel.state == .uploading {
                    Button(L10n.cancel) {
                        viewModel.send(.cancel)
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
                    if viewModel.state == .uploading {
                        ProgressView()
                    } else {
                        Button(L10n.reset) {
                            proxy.reset()
                        }
                        .foregroundStyle(.yellow)
                        .disabled(viewModel.state == .uploading)
                    }
                }
            }
            .ignoresSafeArea()
            .background {
                Color.black
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    error = eventError
                case .deleted:
                    break
                case .uploaded:
                    router.dismissCoordinator()
                }
            }
            .errorMessage($error)
        }
    }

    // MARK: - Square Image Crop View

    struct _SquareImageCropView: UIViewControllerRepresentable {

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
        let proxy: Proxy
        let onImageCropped: (UIImage) -> Void

        func makeUIViewController(context: Context) -> some UIViewController {
            var config = Mantis.Config()

            config.cropViewConfig.backgroundColor = .black.withAlphaComponent(0.9)
            config.cropViewConfig.cropShapeType = .square
            config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
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
}
