//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(macOS)
import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum MacPhotoPickerPresetRatio {
    case canUseMultiplePresetFixedRatio
    case alwaysUsingOnePresetFixedRatio(ratio: CGFloat)
}

private struct MacPhotoPickerModifier: ViewModifier {

    @Binding
    var isPresented: Bool

    @State
    private var selectedImage: NSImage?

    let isSaving: Bool
    let presetRatio: MacPhotoPickerPresetRatio
    let onSave: (NSImage) -> Void

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: $isPresented,
                allowedContentTypes: [.png, .jpeg, .heic],
                allowsMultipleSelection: false
            ) { result in
                guard case let .success(urls) = result,
                      let url = urls.first
                else { return }

                let didStartAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                guard let data = try? Data(contentsOf: url),
                      let image = NSImage(data: data)
                else { return }

                isPresented = false
                selectedImage = image
            }
            .sheet(
                isPresented: Binding(
                    get: { selectedImage != nil },
                    set: { isPresented in
                        if !isPresented {
                            clearSelection()
                        }
                    }
                )
            ) {
                if let selectedImage {
                    MacPhotoCropView(
                        image: selectedImage,
                        presetRatio: presetRatio,
                        isSaving: isSaving,
                        onSave: {
                            clearSelection()
                            onSave($0)
                        },
                        onCancel: clearSelection
                    )
                }
            }
            .disabled(isSaving)
    }

    private func clearSelection() {
        selectedImage = nil
        isPresented = false
    }
}

extension View {

    func photoPicker(
        isPresented: Binding<Bool>,
        isSaving: Bool = false,
        presetRatio: MacPhotoPickerPresetRatio = .canUseMultiplePresetFixedRatio,
        onSave: @escaping (NSImage) -> Void
    ) -> some View {
        modifier(
            MacPhotoPickerModifier(
                isPresented: isPresented,
                isSaving: isSaving,
                presetRatio: presetRatio,
                onSave: onSave
            )
        )
    }
}

private struct MacPhotoCropView: View {

    private struct CropLayout {
        let cropSize: CGSize
        let fittedImageSize: CGSize
        let imageScale: CGFloat
        let effectiveScale: CGFloat
    }

    private let originalImage: NSImage
    private let presetRatio: MacPhotoPickerPresetRatio
    private let isSaving: Bool
    private let onSave: (NSImage) -> Void
    private let onCancel: () -> Void

    @State
    private var image: NSImage
    @State
    private var selectedRatio: CGFloat?
    @State
    private var zoom: CGFloat = 1
    @State
    private var offset: CGSize = .zero
    @State
    private var previewSize: CGSize = .init(width: 700, height: 420)
    @State
    private var dragStartOffset: CGSize = .zero
    @State
    private var zoomStart: CGFloat = 1
    @State
    private var hasChanges = false
    @State
    private var didStartDragging = false
    @State
    private var didStartZooming = false

    init(
        image: NSImage,
        presetRatio: MacPhotoPickerPresetRatio,
        isSaving: Bool,
        onSave: @escaping (NSImage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        originalImage = image
        self.presetRatio = presetRatio
        self.isSaving = isSaving
        self.onSave = onSave
        self.onCancel = onCancel
        _image = State(initialValue: image)

        switch presetRatio {
        case .canUseMultiplePresetFixedRatio:
            _selectedRatio = State(initialValue: nil)
        case let .alwaysUsingOnePresetFixedRatio(ratio):
            _selectedRatio = State(initialValue: ratio)
        }
    }

    private var availableRatios: [(String, CGFloat?)] {
        [
            (L10n.custom, nil),
            ("1:1", 1),
            ("2:3", 2 / 3),
            ("3:2", 3 / 2),
            ("4:3", 4 / 3),
            ("16:9", 16 / 9),
            ("24:7", 24 / 7),
        ]
    }

    private var hasRatioChoices: Bool {
        if case .canUseMultiplePresetFixedRatio = presetRatio {
            return true
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                cropCanvas(in: geometry)
                    .onAppear {
                        previewSize = geometry.size
                    }
                    .onChange(of: geometry.size) {
                        previewSize = geometry.size
                    }
            }
            .frame(minWidth: 640, minHeight: 380)

            if hasRatioChoices {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(availableRatios, id: \.0) { label, ratio in
                            Button(label) {
                                selectedRatio = ratio
                                zoom = 1
                                offset = .zero
                                hasChanges = true
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedRatio == ratio ? .accentColor : nil)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }

            HStack {
                Button(L10n.rotate, systemImage: "rotate.right") {
                    rotateImage()
                }

                Button(L10n.reset, role: .destructive) {
                    reset()
                }
                .disabled(!hasChanges || isSaving)

                Spacer()

                Button(L10n.cancel, role: .cancel, action: onCancel)
                    .disabled(isSaving)

                Button(L10n.save, action: save)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isSaving)
            }
            .padding()
        }
        .frame(minWidth: 720, minHeight: 520)
    }

    @ViewBuilder
    private func cropCanvas(in geometry: GeometryProxy) -> some View {
        let layout = layout(in: geometry.size)

        ZStack {
            Color.black

            Image(nsImage: image)
                .resizable()
                .frame(
                    width: layout.fittedImageSize.width,
                    height: layout.fittedImageSize.height
                )
                .scaleEffect(layout.effectiveScale)
                .offset(offset)

            Rectangle()
                .stroke(.white, lineWidth: 2)
                .frame(width: layout.cropSize.width, height: layout.cropSize.height)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !didStartDragging {
                        dragStartOffset = offset
                        didStartDragging = true
                    }

                    offset = clampedOffset(
                        .init(
                            width: dragStartOffset.width + value.translation.width,
                            height: dragStartOffset.height + value.translation.height
                        ),
                        layout: layout
                    )
                }
                .onEnded { _ in
                    didStartDragging = false
                }
                .simultaneously(
                    with: MagnificationGesture()
                        .onChanged { value in
                            if !didStartZooming {
                                zoomStart = zoom
                                didStartZooming = true
                            }

                            zoom = min(max(zoomStart * value, 0.25), 8)
                            offset = clampedOffset(offset, layout: layout)
                            hasChanges = true
                        }
                        .onEnded { _ in
                            didStartZooming = false
                        }
                )
        )
    }

    private func layout(in size: CGSize) -> CropLayout {
        let imageSize = image.size.width > 0 && image.size.height > 0
            ? image.size
            : .init(width: 1, height: 1)
        let canvasSize = CGSize(
            width: max(size.width - 80, 1),
            height: max(size.height - 80, 1)
        )
        let imageScale = min(
            canvasSize.width / imageSize.width,
            canvasSize.height / imageSize.height
        )
        let fittedImageSize = CGSize(
            width: imageSize.width * imageScale,
            height: imageSize.height * imageScale
        )
        let ratio = selectedRatio ?? imageSize.width / imageSize.height
        let cropSize: CGSize = if ratio >= canvasSize.width / canvasSize.height {
            .init(
                width: canvasSize.width,
                height: canvasSize.width / max(ratio, 0.01)
            )
        } else {
            .init(
                width: canvasSize.height * ratio,
                height: canvasSize.height
            )
        }

        let minimumScale = max(
            cropSize.width / max(fittedImageSize.width, 1),
            cropSize.height / max(fittedImageSize.height, 1),
            0.01
        )

        return CropLayout(
            cropSize: cropSize,
            fittedImageSize: fittedImageSize,
            imageScale: imageScale,
            effectiveScale: max(zoom, minimumScale)
        )
    }

    private func clampedOffset(_ value: CGSize, layout: CropLayout) -> CGSize {
        let displayedSize = CGSize(
            width: layout.fittedImageSize.width * layout.effectiveScale,
            height: layout.fittedImageSize.height * layout.effectiveScale
        )
        let maximum = CGSize(
            width: max((displayedSize.width - layout.cropSize.width) / 2, 0),
            height: max((displayedSize.height - layout.cropSize.height) / 2, 0)
        )

        return .init(
            width: min(max(value.width, -maximum.width), maximum.width),
            height: min(max(value.height, -maximum.height), maximum.height)
        )
    }

    private func rotateImage() {
        let size = image.size
        let rotatedSize = CGSize(width: size.height, height: size.width)
        let rotated = NSImage(size: rotatedSize)

        rotated.lockFocus()
        let transform = NSAffineTransform()
        transform.translateX(by: rotatedSize.width / 2, yBy: rotatedSize.height / 2)
        transform.rotate(byDegrees: 90)
        transform.translateX(by: -size.width / 2, yBy: -size.height / 2)
        transform.concat()
        image.draw(
            in: .init(origin: .zero, size: size),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        rotated.unlockFocus()

        image = rotated
        zoom = 1
        offset = .zero
        hasChanges = true
    }

    private func reset() {
        image = originalImage
        zoom = 1
        offset = .zero
        hasChanges = false

        switch presetRatio {
        case .canUseMultiplePresetFixedRatio:
            selectedRatio = nil
        case let .alwaysUsingOnePresetFixedRatio(ratio):
            selectedRatio = ratio
        }
    }

    private func save() {
        guard let sourceImage = image.cgImage else { return }

        let layout = layout(in: previewSize)
        let displayedSize = CGSize(
            width: layout.fittedImageSize.width * layout.effectiveScale,
            height: layout.fittedImageSize.height * layout.effectiveScale
        )
        let displayedOrigin = CGPoint(
            x: (previewSize.width - displayedSize.width) / 2 + offset.width,
            y: (previewSize.height - displayedSize.height) / 2 + offset.height
        )
        let cropOrigin = CGPoint(
            x: (previewSize.width - layout.cropSize.width) / 2,
            y: (previewSize.height - layout.cropSize.height) / 2
        )
        let sourceScale = layout.effectiveScale * layout.imageScale
        let sourceRect = CGRect(
            x: (cropOrigin.x - displayedOrigin.x) / sourceScale,
            y: (cropOrigin.y - displayedOrigin.y) / sourceScale,
            width: layout.cropSize.width / sourceScale,
            height: layout.cropSize.height / sourceScale
        )
        let pixelScale = CGSize(
            width: CGFloat(sourceImage.width) / max(image.size.width, 1),
            height: CGFloat(sourceImage.height) / max(image.size.height, 1)
        )
        let pixelRect = CGRect(
            x: sourceRect.minX * pixelScale.width,
            y: CGFloat(sourceImage.height) - sourceRect.maxY * pixelScale.height,
            width: sourceRect.width * pixelScale.width,
            height: sourceRect.height * pixelScale.height
        )
        .intersection(
            .init(
                x: 0,
                y: 0,
                width: sourceImage.width,
                height: sourceImage.height
            )
        )
        .integral

        guard let cropped = sourceImage.cropping(to: pixelRect),
              cropped.width > 0,
              cropped.height > 0
        else { return }

        onSave(
            NSImage(
                cgImage: cropped,
                size: .init(width: cropped.width, height: cropped.height)
            )
        )
    }
}
#endif
