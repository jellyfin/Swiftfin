//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import Mantis
import SwiftUI

class UserProfileImageViewModel: ViewModel, Eventful, Stateful {

    enum Action: Equatable {
        case cancel
        case upload(UIImage)
    }

    enum Event: Hashable {
        case error(JellyfinAPIError)
        case uploaded
    }

    enum State: Hashable {
        case initial
        case uploading
    }

    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var eventSubject: PassthroughSubject<Event, Never> = .init()
    private var uploadCancellable: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            uploadCancellable?.cancel()

            return .initial
        case let .upload(image):

            uploadCancellable = Task {
                do {
                    try await upload(image: image)

                    await MainActor.run {
                        self.eventSubject.send(.uploaded)
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .uploading
        }
    }

    private func upload(image: UIImage) async throws {
        let request = Paths.postUserImage(
            userID: userSession.user.id,
            imageType: "Primary",
            index: nil,
            image.jpegData(compressionQuality: 1)?.base64EncodedData()
        )

        let _ = try await userSession.client.send(request)
    }
}

struct SquareImageCropView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: UserProfileImageCoordinator.Router

    @State
    private var error: Error? = nil
    @State
    private var isPresentingError: Bool = false
    @StateObject
    private var proxy: _SquareImageCropView.Proxy = .init()
    @StateObject
    private var viewModel = UserProfileImageViewModel()

    let image: UIImage

    var body: some View {
        _SquareImageCropView(initialImage: image, proxy: proxy) {
            viewModel.send(.upload($0))
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .topBarTrailing {

            Button("Rotate", systemImage: "rotate.right") {
                proxy.rotate()
            }
            .foregroundStyle(.gray)
            .disabled(viewModel.state == .uploading)

            Button {
                proxy.crop()
            } label: {
                Text("Save")
                    .foregroundStyle(accentColor.overlayColor)
                    .font(.headline)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background {
                        accentColor
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(viewModel.state == .uploading)
            .opacity(viewModel.state == .uploading ? 0 : 1)
            .overlay {
                if viewModel.state == .uploading {
                    ProgressView()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button("Reset") {
                    proxy.reset()
                }
                .foregroundStyle(.yellow)
                .disabled(viewModel.state == .uploading)
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
                isPresentingError = true
            case .uploaded:
                router.dismissCoordinator()
            }
        }
        .alert(
            L10n.error.text,
            isPresented: $isPresentingError,
            presenting: error
        ) { _ in
            Button(L10n.dismiss, role: .destructive)
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

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
        ) {
            print("a")
        }

        func cropViewControllerDidBeginResize(
            _ cropViewController: CropViewController
        ) {
            print("b")
        }

        func cropViewControllerDidEndResize(
            _ cropViewController: Mantis.CropViewController,
            original: UIImage,
            cropInfo: Mantis.CropInfo
        ) {}
    }
}
