//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import ObjectiveC.runtime
import SwiftUI
import UIKit

struct NotchMeasurement: Equatable, Sendable {

    let size: CGSize
    /// Physical screen radius, or zero when the view does not cover the display.
    var displayCornerRadius: CGFloat = 0
    /// Cutout bounds in the measured view's coordinates; nil when unavailable.
    let cutout: CGRect?
    let systemInsets: EdgeInsets
    /// Private cutout insets, or systemInsets when the private API is unavailable.
    let insets: EdgeInsets
}

struct NotchReader<Content: View>: View {

    @State
    private var measurement: NotchMeasurement?

    @ViewBuilder
    let content: (NotchMeasurement?) -> Content

    var body: some View {
        content(measurement)
            .overlay {
                NotchMeasurementReader {
                    measurement = $0
                }
                .ignoresSafeArea(.container)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }
}

@MainActor
enum NotchDeviceReader {

    static func measure(
        _ view: UIView,
        layoutDirection: LayoutDirection = .leftToRight
    ) -> NotchMeasurement? {
        guard let window = view.window,
              view.bounds.width > 0,
              view.bounds.height > 0
        else { return nil }

        let bounds = view.bounds
        let safe = view.safeAreaLayoutGuide.layoutFrame.intersection(bounds)
            .intersection(view.convert(window.safeAreaLayoutGuide.layoutFrame, from: window))
        let left = safe.isNull ? 0 : max(0, safe.minX - bounds.minX)
        let right = safe.isNull ? 0 : max(0, bounds.maxX - safe.maxX)
        let system = EdgeInsets(
            top: safe.isNull ? bounds.height : max(0, safe.minY - bounds.minY),
            leading: layoutDirection == .leftToRight ? left : right,
            bottom: safe.isNull ? 0 : max(0, bounds.maxY - safe.maxY),
            trailing: layoutDirection == .leftToRight ? right : left
        )
        var fallback = NotchMeasurement(
            size: bounds.size,
            cutout: nil,
            systemInsets: system,
            insets: system
        )
        let screen = window.screen

        let displayFrame = view.convert(bounds, to: screen.coordinateSpace)
        guard abs(displayFrame.minX) < 1,
              abs(displayFrame.minY) < 1,
              abs(displayFrame.width - screen.bounds.width) < 1,
              abs(displayFrame.height - screen.bounds.height) < 1
        else { return fallback }

        fallback.displayCornerRadius = privateCornerRadius(screen)

        guard screen === UIScreen.main,
              let orientation = window.windowScene?.effectiveGeometry.interfaceOrientation,
              orientation != .unknown,
              let portrait = privateRect(screen)
        else { return fallback }

        let rect = view.convert(portrait, from: screen.fixedCoordinateSpace)
            .offsetBy(dx: -bounds.minX, dy: -bounds.minY)
        guard let insets = cutoutInsets(enclosing: rect, in: bounds.size, layoutDirection: layoutDirection) else { return fallback }

        return NotchMeasurement(
            size: bounds.size,
            displayCornerRadius: fallback.displayCornerRadius,
            cutout: rect,
            systemInsets: system,
            insets: insets
        )
    }

    static func cutoutInsets(
        enclosing rect: CGRect,
        in size: CGSize,
        layoutDirection: LayoutDirection = .leftToRight
    ) -> EdgeInsets? {
        guard size.width > 0,
              size.height > 0,
              rect.width > 0,
              rect.height > 0,
              [rect.minX, rect.minY, rect.width, rect.height, size.width, size.height].allSatisfy(\.isFinite),
              CGRect(origin: .zero, size: size).contains(rect)
        else { return nil }

        // A floating island includes its gap from the nearest physical edge.
        let distances = [rect.minY, rect.minX, size.height - rect.maxY, size.width - rect.maxX]
        let left: WritableKeyPath<EdgeInsets, CGFloat> = layoutDirection == .leftToRight ? \.leading : \.trailing
        let right: WritableKeyPath<EdgeInsets, CGFloat> = layoutDirection == .leftToRight ? \.trailing : \.leading
        var insets = EdgeInsets()

        switch distances.enumerated().min(by: { $0.element < $1.element })?.offset {
        case 0:
            insets.top = rect.maxY
        case 1:
            insets[keyPath: left] = rect.maxX
        case 2:
            insets.bottom = size.height - rect.minY
        default:
            insets[keyPath: right] = size.width - rect.minX
        }

        return insets
    }

    static func privateRect(_ screen: UIScreen) -> CGRect? {
        guard let selector = "X2V4Y2x1c2lvbkFyZWE=".base64Decoded?.asSelector(),
              let method = class_getInstanceMethod(type(of: screen), selector),
              method_getNumberOfArguments(method) == 2,
              returns(method, type: "@"),
              let area = screen.perform(selector)?.takeUnretainedValue() as? NSObject
        else { return nil }

        guard let rectSelector = "cmVjdA==".base64Decoded?.asSelector(),
              let rectMethod = class_getInstanceMethod(type(of: area), rectSelector),
              method_getNumberOfArguments(rectMethod) == 2,
              returns(rectMethod, type: String(cString: NSValue(cgRect: .zero).objCType))
        else { return nil }

        typealias Getter = @convention(c) (AnyObject, Selector) -> CGRect
        let getter = unsafeBitCast(method_getImplementation(rectMethod), to: Getter.self)
        return getter(area, rectSelector)
    }

    private static func privateCornerRadius(_ screen: UIScreen) -> CGFloat {
        guard let selector = "X2Rpc3BsYXlDb3JuZXJSYWRpdXM=".base64Decoded?.asSelector(),
              let method = class_getInstanceMethod(type(of: screen), selector),
              method_getNumberOfArguments(method) == 2,
              returns(method, type: "d")
        else { return 0 }

        typealias Getter = @convention(c) (AnyObject, Selector) -> Double
        let getter = unsafeBitCast(method_getImplementation(method), to: Getter.self)
        let radius = getter(screen, selector)
        guard radius.isFinite, radius >= 0,
              radius <= min(screen.bounds.width, screen.bounds.height) / 2
        else { return 0 }
        return CGFloat(radius)
    }

    private static func returns(_ method: Method, type: String) -> Bool {
        let encoding = method_copyReturnType(method)
        defer { free(encoding) }
        return String(cString: encoding) == type
    }
}

private final class NotchProbe: UIView {

    private var geometryObservation: NSKeyValueObservation?

    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        onLayout?()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // A flip changes geometry without changing view size or safe insets.
        geometryObservation = window?.windowScene?.observe(\.effectiveGeometry, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.onLayout?()
            }
        }
        onLayout?()
    }
}

private struct NotchMeasurementReader: UIViewRepresentable {

    let onChange: (NotchMeasurement) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> NotchProbe {
        let view = NotchProbe()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: NotchProbe, context: Context) {
        let coordinator = context.coordinator
        let layoutDirection = context.environment.layoutDirection
        coordinator.onChange = onChange

        view.onLayout = { [weak view, weak coordinator] in
            guard let view,
                  let coordinator,
                  let value = NotchDeviceReader.measure(view, layoutDirection: layoutDirection),
                  coordinator.last != value
            else { return }

            coordinator.last = value

            DispatchQueue.main.async { [weak view, weak coordinator] in
                guard let view,
                      let coordinator,
                      coordinator.last == value,
                      NotchDeviceReader.measure(view, layoutDirection: layoutDirection) == value
                else { return }

                coordinator.onChange?(value)
            }
        }

        view.onLayout?()
    }

    final class Coordinator {

        var last: NotchMeasurement?
        var onChange: ((NotchMeasurement) -> Void)?
    }
}
