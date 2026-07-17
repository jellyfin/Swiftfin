//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import SwiftUI

extension View {

    var backport: Backport<Self> {
        Backport(content: self)
    }

    @ViewBuilder
    func assign<P: Publisher>(_ publisher: P, to binding: Binding<P.Output>) -> some View where P.Failure == Never {
        onReceive(publisher) { output in
            binding.wrappedValue = output
        }
    }

    @ViewBuilder
    func blurred(style: UIBlurEffect.Style = .regular) -> some View {
        overlay {
            BlurView(style: style)
        }
    }

    @ViewBuilder
    func bottomEdgeGradient(bottomColor: Color) -> some View {
        modifier(BottomEdgeGradientModifier(bottomColor: bottomColor))
    }

    func copy<Value>(modifying keyPath: WritableKeyPath<Self, Value>, with newValue: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }

    @ViewBuilder
    func cornerRadius(
        _ radius: CGFloat,
        corners: RectangleCorner = .all,
        style: RoundedCornerStyle = .circular,
        container: Bool = false
    ) -> some View {
        // Note: UnevenRoundedRectangle with all equal radii has
        // been found to perform worse than RoundedRectangle
        if corners == .all {
            let shape = RoundedRectangle(cornerRadius: radius, style: style)

            clipShape(shape)
                .if(container) { $0.containerShape(shape) }
        } else {
            let shape = UnevenRoundedRectangle(
                topLeadingRadius: corners.contains(.topLeft) ? radius : 0,
                bottomLeadingRadius: corners.contains(.bottomLeft) ? radius : 0,
                bottomTrailingRadius: corners.contains(.bottomRight) ? radius : 0,
                topTrailingRadius: corners.contains(.topRight) ? radius : 0,
                style: style
            )

            clipShape(shape)
                .if(container) { $0.containerShape(shape) }
        }
    }

    /// Apply a corner radius as a ratio of a view's side
    @ViewBuilder
    func cornerRadius(
        ratio: CGFloat,
        of side: KeyPath<CGSize, CGFloat>,
        corners: RectangleCorner = .all,
        style: RoundedCornerStyle = .circular
    ) -> some View {
        modifier(
            OnSizeChangedModifier { size in
                let radius = size[keyPath: side] * ratio
                self.cornerRadius(radius, corners: corners, style: style, container: true)
            }
        )
    }

    @ViewBuilder
    func edgePadding(_ edges: Edge.Set = .all) -> some View {
        padding(edges, EdgeInsets.edgePadding)
    }

    @ViewBuilder
    @inlinable
    func enabled(_ enabled: Bool) -> some View {
        disabled(!enabled)
    }

    @ViewBuilder
    @inlinable
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }

    // TODO: rename `errorAlert`

    /// Error Message Alert
    @ViewBuilder
    func errorMessage(
        _ error: Binding<Error?>,
        dismissAction: @escaping () -> Void = {}
    ) -> some View {
        alert(
            Text(L10n.error),
            isPresented: .constant(error.wrappedValue != nil),
            presenting: error.wrappedValue
        ) { _ in
            Button(L10n.dismiss, role: .cancel) {
                error.wrappedValue = nil
                dismissAction()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .backport
        .onChange(of: error.wrappedValue != nil) { _, hasError in
            guard hasError else { return }
            UIDevice.feedback(.error)
        }
    }

    @ViewBuilder
    @inlinable
    func hidden(_ isHidden: Bool) -> some View {
        if isHidden {
            hidden()
        } else {
            self
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if` statement.
    @ViewBuilder
    @inlinable
    func `if`(_ condition: Bool, @ViewBuilder transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if/else` statement.
    @ViewBuilder
    @inlinable
    func `if`<Content: View>(
        _ condition: Bool,
        @ViewBuilder transformIf: (Self) -> Content,
        @ViewBuilder transformElse: (Self) -> Content
    ) -> some View {
        if condition {
            transformIf(self)
        } else {
            transformElse(self)
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if let` statement.
    @ViewBuilder
    @inlinable
    func ifLet<Value>(
        _ value: Value?,
        @ViewBuilder transform: (Self, Value) -> some View
    ) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if let/else` statement.
    @ViewBuilder
    @inlinable
    func ifLet<Value, Content: View>(
        _ value: Value?,
        @ViewBuilder transformIf: (Self, Value) -> Content,
        @ViewBuilder transformElse: (Self) -> Content
    ) -> some View {
        if let value {
            transformIf(self, value)
        } else {
            transformElse(self)
        }
    }

    // TODO: rename `invertedMask`?
    @ViewBuilder
    func inverseMask(alignment: Alignment = .center, @ViewBuilder _ content: @escaping () -> some View) -> some View {
        mask(alignment: alignment) {
            content()
                .foregroundColor(.black)
                .background(.white)
                .compositingGroup()
                .luminanceToAlpha()
        }
    }

    @ViewBuilder
    func isEditing(_ isEditing: Bool) -> some View {
        environment(\.isEditing, isEditing)
    }

    @ViewBuilder
    func isHighlighted(_ isHighlighted: Bool) -> some View {
        environment(\.isHighlighted, isHighlighted)
    }

    @ViewBuilder
    func isSelected(_ isSelected: Bool) -> some View {
        environment(\.isSelected, isSelected)
    }

    /// - Important: Do not use this to add or remove a view from the view heirarchy.
    ///              Use a conditional statement instead.
    @ViewBuilder
    @inlinable
    func isVisible(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
    }

    @ViewBuilder
    func letterPickerBar(filterViewModel: FilterViewModel?) -> some View {
        modifier(
            LetterPickerBarModifier(viewModel: filterViewModel)
        )
    }

    @ViewBuilder
    func mask(
        gradient: MaskGradientModifier.Style,
        @ArrayBuilder<MaskGradientModifier.Stop> stops: () -> [MaskGradientModifier.Stop]
    ) -> some View {
        modifier(MaskGradientModifier(style: gradient, stops: stops()))
    }

    @ViewBuilder
    func onAppDidEnterBackground(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationDidEnterBackground, perform: action)
    }

    @ViewBuilder
    func onAppWillEnterForeground(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationWillEnterForeground, perform: action)
    }

    @ViewBuilder
    func onAppWillResignActive(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationWillResignActive, perform: action)
    }

    @ViewBuilder
    func onAppWillTerminate(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationWillTerminate, perform: action)
    }

    /// Perform an action on the final disappearance of a `View`.
    @ViewBuilder
    func onFinalDisappear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFinalDisappearModifier(action: action))
    }

    /// Perform an action on the first appearance of a `View`.
    @ViewBuilder
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }

    @ViewBuilder
    func onNotification<P>(_ key: Notifications.Key<P>, perform action: @escaping (P) -> Void) -> some View {
        modifier(
            OnReceiveNotificationModifier(
                key: key,
                onReceive: action
            )
        )
    }

    @ViewBuilder
    func onSceneDidEnterBackground(_ action: @escaping () -> Void) -> some View {
        onNotification(.sceneDidEnterBackground, perform: action)
    }

    @ViewBuilder
    func onScenePhase(_ phase: ScenePhase, _ action: @escaping () -> Void) -> some View {
        modifier(OnScenePhaseChangedModifier(phase: phase, action: action))
    }

    @ViewBuilder
    func onSceneWillEnterForeground(_ action: @escaping () -> Void) -> some View {
        onNotification(.sceneWillEnterForeground, perform: action)
    }

    @ViewBuilder
    func posterAspectRatio(
        _ type: PosterDisplayType,
        contentMode: ContentMode = .fill
    ) -> some View {
        switch type {
        case .landscape:
            aspectRatio(1.77, contentMode: contentMode)
        case .portrait:
            aspectRatio(2 / 3, contentMode: contentMode)
        case .square:
            aspectRatio(1.0, contentMode: contentMode)
        }
    }

    @ViewBuilder
    func posterBorder() -> some View {
        overlay {
            ContainerRelativeShape()
                .stroke(
                    .white.opacity(0.1),
                    lineWidth: 1
                )
                .clipped()
        }
    }

    @ViewBuilder
    func posterCornerRadius(
        _ type: PosterDisplayType
    ) -> some View {
        switch type {
        case .landscape:
            cornerRadius(ratio: 1 / 30, of: \.width)
        case .portrait, .square:
            cornerRadius(ratio: 0.0375, of: \.width)
        }
    }

    @ViewBuilder
    func posterShadow() -> some View {
        shadow(radius: 4, y: 2)
    }

    /// Applies the aspect ratio, corner radius, and border for the given `PosterType`
    ///
    /// Note: will not apply `posterShadow`
    @ViewBuilder
    func posterStyle(
        _ type: PosterDisplayType,
        contentMode: ContentMode = .fill
    ) -> some View {
        switch type {
        case .landscape:
            posterAspectRatio(type, contentMode: contentMode)
            #if !os(tvOS)
                .posterBorder()
                .posterCornerRadius(type)
            #endif
        case .portrait:
            posterAspectRatio(type, contentMode: contentMode)
            #if !os(tvOS)
                .posterBorder()
                .posterCornerRadius(type)
            #endif
        case .square:
            posterAspectRatio(type, contentMode: contentMode)
            #if os(iOS)
                .posterBorder()
                .posterCornerRadius(type)
            #endif
        }
    }

    @ViewBuilder
    func preference<Key: PreferenceKey, V>(
        key: Key.Type,
        @ArrayBuilder<V> value: () -> [V]
    ) -> some View where Key.Value == [V] {
        preference(key: Key.self, value: value())
    }

    @ViewBuilder
    func scrollIfLargerThanContainer(axes: Axis.Set = .vertical, padding: CGFloat = 0, alignment: Alignment = .center) -> some View {
        modifier(ScrollIfLargerThanContainerModifier(axes: axes, padding: padding, alignment: alignment))
    }

    @ViewBuilder
    func scrollViewOffset(_ scrollViewOffset: Binding<CGFloat>) -> some View {
        modifier(ScrollViewOffsetModifier(scrollViewOffset: scrollViewOffset))
    }

    /// Perform an action as the view appears given the time interval
    /// since the view last disappeared.
    @ViewBuilder
    func sinceLastDisappear(perform action: @escaping (TimeInterval) -> Void) -> some View {
        modifier(SinceLastDisappearModifier(action: action))
    }

    @ViewBuilder
    func topBarTrailing(@ViewBuilder content: @escaping () -> some View) -> some View {
        toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing,
                content: content
            )
        }
    }

    // TODO: look at changing to symbolEffect
    @ViewBuilder
    func videoPlayerActionButtonTransition() -> some View {
        transition(.opacity.combined(with: .scale).animation(.snappy))
    }

    // MARK: debug

    // Useful modifiers during development for layout

    #if DEBUG
    @ViewBuilder
    func debugBackground(_ fill: some ShapeStyle = .red.opacity(0.5)) -> some View {
        background {
            Rectangle()
                .fill(fill)
        }
    }

    @ViewBuilder
    func debugCross(_ fill: some ShapeStyle = .red) -> some View {
        debugVLine(fill)
            .debugHLine(fill)
    }

    @ViewBuilder
    func debugHLine(_ fill: some ShapeStyle) -> some View {
        overlay {
            Rectangle()
                .fill(fill)
                .frame(height: 4)
        }
    }

    @ViewBuilder
    func debugOverlay(_ fill: some ShapeStyle = .red.opacity(0.5)) -> some View {
        overlay {
            Rectangle()
                .fill(fill)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    func debugVLine(_ fill: some ShapeStyle) -> some View {
        overlay {
            Rectangle()
                .fill(fill)
                .frame(width: 4)
        }
    }
    #endif
}
