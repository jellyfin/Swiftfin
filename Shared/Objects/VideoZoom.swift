//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreGraphics
import Foundation

struct VideoZoom {

    let geometry: Geometry?
    private var restingTransform: Transform?
    private var pinch: Pinch?
    private var panOffset: CGSize?

    init(geometry: Geometry? = nil) {
        self.geometry = geometry
    }

    var transform: Transform? {
        pinch?.transform ?? restingTransform
    }

    var canPan: Bool {
        (transform?.scale ?? 1) > 1
    }

    var isPinching: Bool {
        pinch != nil
    }

    var isPanning: Bool {
        panOffset != nil
    }

    var isInteracting: Bool {
        isPinching || isPanning
    }

    var stop: CGFloat? {
        pinch?.stop
    }

    var isFillBorderPresented: Bool {
        pinch?.isInFillSnapRange == true
    }

    mutating func beginPinch(input: CGFloat, location: CGPoint, fillsViewport: Bool) -> Bool {
        guard let geometry else { return false }

        let initial = transform ?? Transform(scale: fillsViewport ? geometry.fillScale : 1)
        pinch = Pinch(
            transform: Transform(scale: min(initial.scale, Self.maximumScale), offset: initial.offset),
            geometry: geometry,
            input: input,
            location: location
        )
        return true
    }

    mutating func updatePinch(input: CGFloat, location: CGPoint) {
        guard var pinch else { return }

        pinch.update(input, location: location)
        self.pinch = pinch
    }

    mutating func endPinch() {
        guard let pinch else { return }

        restingTransform = pinch.settledTransform
        self.pinch = nil
    }

    mutating func beginPan() {
        guard canPan, !isPinching else { return }

        panOffset = transform?.offset
    }

    mutating func updatePan(translation: CGPoint) {
        guard let panOffset, let transform, let geometry else { return }

        restingTransform = Transform(
            scale: transform.scale,
            offset: geometry.rubberBandedOffset(
                CGSize(width: panOffset.width + translation.x, height: panOffset.height + translation.y),
                at: transform.scale
            )
        )
    }

    mutating func endPan() {
        guard isPanning, let transform, let geometry else { return }

        restingTransform = Transform(
            scale: transform.scale,
            offset: geometry.constrainedOffset(transform.offset, at: transform.scale)
        )
        panOffset = nil
    }

    mutating func endInteraction() {
        endPinch()
        endPan()
    }

    mutating func reset() {
        restingTransform = nil
        pinch = nil
        panOffset = nil
    }

    static let maximumScale: CGFloat = 8

    static func displayedScale(_ scale: CGFloat) -> CGFloat {
        min(maximumScale, max(1, scale))
    }

    static func isInFillSnapRange(_ scale: CGFloat, fillScale: CGFloat) -> Bool {
        guard fillScale > 1.0001, fillScale <= maximumScale,
              scale > 1, scale <= maximumScale
        else { return false }

        var radius = min(fillScale * 0.05, (fillScale - 1) / 2)

        if fillScale < maximumScale {
            radius = min(radius, (maximumScale - fillScale) / 2)
        }

        return abs(scale - fillScale) <= radius
    }

    struct Transform: Equatable {
        let scale: CGFloat
        var offset: CGSize = .zero
    }

    /// Require leaving a stop before ticking again
    struct StopFeedback {
        private var lastStop: CGFloat?

        init(stop: CGFloat? = nil) {
            lastStop = stop
        }

        mutating func update(scale: CGFloat, stop: CGFloat?) -> Bool {
            let scale = VideoZoom.displayedScale(scale)
            if let lastStop, stop != lastStop, abs(scale / lastStop - 1) > 0.025 {
                self.lastStop = nil
            }
            guard let stop, stop != lastStop else { return false }

            lastStop = stop
            return true
        }
    }

    struct Geometry: Equatable {

        let viewportSize: CGSize
        let fitFrame: CGRect
        let fillScale: CGFloat

        init?(videoSize: CGSize, viewportSize: CGSize, fitViewport: CGRect) {
            guard [
                videoSize.width,
                videoSize.height,
                viewportSize.width,
                viewportSize.height,
                fitViewport.width,
                fitViewport.height
            ].allSatisfy({ $0.isFinite && $0 > 0 })
            else { return nil }

            let fit = min(fitViewport.width / videoSize.width, fitViewport.height / videoSize.height)
            let size = CGSize(width: videoSize.width * fit, height: videoSize.height * fit)

            self.viewportSize = viewportSize
            self.fitFrame = CGRect(
                x: fitViewport.midX - size.width / 2,
                y: fitViewport.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
            self.fillScale = max(viewportSize.width / size.width, viewportSize.height / size.height)
        }

        func frame(at scale: CGFloat, offset: CGSize = .zero) -> CGRect {
            let progress = fillScale > 1 ? min(1, max(0, (scale - 1) / (fillScale - 1))) : 1
            let center = CGPoint(
                x: fitFrame.midX + (viewportSize.width / 2 - fitFrame.midX) * progress,
                y: fitFrame.midY + (viewportSize.height / 2 - fitFrame.midY) * progress
            )

            return CGRect(
                x: center.x + offset.width - fitFrame.width * scale / 2,
                y: center.y + offset.height - fitFrame.height * scale / 2,
                width: fitFrame.width * scale,
                height: fitFrame.height * scale
            )
        }
    }

    struct Pinch {

        private let geometry: Geometry
        private let scalePerInput: CGFloat
        private let anchor: CGPoint
        private(set) var transform: Transform
        private var location: CGPoint

        init(
            transform: Transform,
            geometry: Geometry,
            input: CGFloat = 1,
            location: CGPoint = .zero
        ) {
            self.geometry = geometry
            self.scalePerInput = transform.scale / (input.isFinite && input > 0 ? input : 1)
            self.transform = transform
            self.location = location
            self.anchor = geometry.contentPoint(at: location, in: transform)
        }

        mutating func update(_ input: CGFloat, location: CGPoint? = nil) {
            guard input.isFinite, input > 0 else { return }

            let raw = scalePerInput * input
            let scale: CGFloat

            if raw < 1 {
                let distance = 1 - raw
                scale = 1 - 0.18 * distance / (1 + distance)
            } else if raw > VideoZoom.maximumScale {
                let distance = raw / VideoZoom.maximumScale - 1
                scale = VideoZoom.maximumScale * (1 + 0.18 * (1 - 1 / (1 + distance)))
            } else {
                scale = raw
            }

            if let location {
                self.location = location
            }

            transform = geometry.transform(scale: scale, anchor: anchor, location: self.location)
        }

        var scale: CGFloat {
            transform.scale
        }

        var offset: CGSize {
            transform.offset
        }

        var settledScale: CGFloat {
            isInFillSnapRange ? geometry.fillScale : VideoZoom.displayedScale(scale)
        }

        var isInFillSnapRange: Bool {
            VideoZoom.isInFillSnapRange(scale, fillScale: geometry.fillScale)
        }

        var settledTransform: Transform {
            if isInFillSnapRange {
                return Transform(scale: geometry.fillScale)
            }
            let targetScale = settledScale

            guard targetScale != scale else {
                return transform
            }

            return geometry.transform(
                scale: targetScale,
                anchor: geometry.contentPoint(at: location, in: transform),
                location: location
            )
        }

        var stop: CGFloat? {
            if scale <= 1.0001 {
                return 1
            }
            if scale >= VideoZoom.maximumScale {
                return VideoZoom.maximumScale
            }
            return isInFillSnapRange ? geometry.fillScale : nil
        }
    }
}

extension VideoZoom.Geometry {

    fileprivate func contentPoint(at location: CGPoint, in transform: VideoZoom.Transform) -> CGPoint {
        let frame = frame(at: transform.scale, offset: transform.offset)
        return CGPoint(
            x: (location.x - frame.minX) / transform.scale,
            y: (location.y - frame.minY) / transform.scale
        )
    }

    fileprivate func transform(scale: CGFloat, anchor: CGPoint, location: CGPoint) -> VideoZoom.Transform {
        let frame = frame(at: scale)
        return VideoZoom.Transform(
            scale: scale,
            offset: constrainedOffset(
                CGSize(width: location.x - frame.minX - anchor.x * scale, height: location.y - frame.minY - anchor.y * scale),
                at: scale
            )
        )
    }

    func constrainedOffset(_ offset: CGSize, at scale: CGFloat) -> CGSize {
        let frame = frame(at: scale)

        return CGSize(
            width: frame.width > viewportSize.width
                ? min(-frame.minX, max(viewportSize.width - frame.maxX, offset.width)) : 0,
            height: frame.height > viewportSize.height
                ? min(-frame.minY, max(viewportSize.height - frame.maxY, offset.height)) : 0
        )
    }

    fileprivate func rubberBandedOffset(_ offset: CGSize, at scale: CGFloat) -> CGSize {
        let constrained = constrainedOffset(offset, at: scale)

        func resistance(_ distance: CGFloat, dimension: CGFloat) -> CGFloat {
            let resisted = -dimension * expm1(-abs(distance) * 0.55 / dimension)
            return distance < 0 ? -resisted : resisted
        }

        return CGSize(
            width: constrained.width + resistance(offset.width - constrained.width, dimension: viewportSize.width),
            height: constrained.height + resistance(offset.height - constrained.height, dimension: viewportSize.height)
        )
    }
}
