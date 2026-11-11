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

    @ContentBuilder
    func assign<P: Publisher>(_ publisher: P, to binding: Binding<P.Output>) -> some View where P.Failure == Never {
        onReceive(publisher) { output in
            binding.wrappedValue = output
        }
    }

    @ContentBuilder
    func blurred(style: UIBlurEffect.Style = .regular) -> some View {
        overlay {
            BlurView(style: style)
        }
    }

    @ContentBuilder
    func bottomEdgeGradient(bottomColor: Color) -> some View {
        modifier(BottomEdgeGradientModifier(bottomColor: bottomColor))
    }

    func copy<Value>(modifying keyPath: WritableKeyPath<Self, Value>, with newValue: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue

        return copy
    }

    @ContentBuilder
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
    @ContentBuilder
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

    @ContentBuilder
    func edgePadding(_ edges: Edge.Set = .all) -> some View {
        modifier(EdgePaddingModifier(edges: edges))
    }

    @ContentBuilder
    @inlinable
    func enabled(_ enabled: Bool) -> some View {
        disabled(!enabled)
    }

    @inlinable
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }

    // TODO: rename `errorAlert`

    /// Error Message Alert
    @ContentBuilder
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
        .onChange(of: error.wrappedValue != nil) {
            guard error.wrappedValue != nil else { return }

            UIDevice.feedback(.error)
        }
    }

    @ContentBuilder
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
    @ContentBuilder
    @inlinable
    func `if`(_ condition: Bool, @ContentBuilder transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if/else` statement.
    @ContentBuilder
    @inlinable
    func `if`<Content: View>(
        _ condition: Bool,
        @ContentBuilder transformIf: (Self) -> Content,
        @ContentBuilder transformElse: (Self) -> Content
    ) -> some View {
        if condition {
            transformIf(self)
        } else {
            transformElse(self)
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if let` statement.
    @ContentBuilder
    @inlinable
    func ifLet<Value>(
        _ value: Value?,
        @ContentBuilder transform: (Self, Value) -> some View
    ) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    /// - Important: Do *not* use this modifier for dynamically showing/hiding views.
    ///              Instead, use a native `if let/else` statement.
    @ContentBuilder
    @inlinable
    func ifLet<Value, Content: View>(
        _ value: Value?,
        @ContentBuilder transformIf: (Self, Value) -> Content,
        @ContentBuilder transformElse: (Self) -> Content
    ) -> some View {
        if let value {
            transformIf(self, value)
        } else {
            transformElse(self)
        }
    }

    // TODO: rename `invertedMask`?
    @ContentBuilder
    func inverseMask(alignment: Alignment = .center, @ContentBuilder _ content: @escaping () -> some View) -> some View {
        mask(alignment: alignment) {
            content()
                .foregroundStyle(.black)
                .background(.white)
                .compositingGroup()
                .luminanceToAlpha()
        }
    }

    @ContentBuilder
    func isEditing(_ isEditing: Bool) -> some View {
        environment(\.isEditing, isEditing)
    }

    @ContentBuilder
    func isHighlighted(_ isHighlighted: Bool) -> some View {
        environment(\.isHighlighted, isHighlighted)
    }

    @ContentBuilder
    func isSelected(_ isSelected: Bool) -> some View {
        environment(\.isSelected, isSelected)
    }

    /// - Important: Do not use this to add or remove a view from the view heirarchy.
    ///              Use a conditional statement instead.
    @ContentBuilder
    @inlinable
    func isVisible(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
            .accessibilityHidden(!isVisible)
    }

    @ContentBuilder
    func letterPickerBar(filterViewModel: FilterViewModel?) -> some View {
        modifier(
            LetterPickerBarModifier(viewModel: filterViewModel)
        )
    }

    @ContentBuilder
    func mask(
        gradient: MaskGradientModifier.Style,
        @ArrayBuilder<MaskGradientModifier.Stop> stops: () -> [MaskGradientModifier.Stop]
    ) -> some View {
        modifier(MaskGradientModifier(style: gradient, stops: stops()))
    }

    @ContentBuilder
    func onAppDidEnterBackground(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationDidEnterBackground, perform: action)
    }

    @ContentBuilder
    func onAppWillEnterForeground(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationWillEnterForeground, perform: action)
    }

    @ContentBuilder
    func onAppWillResignActive(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationWillResignActive, perform: action)
    }

    @ContentBuilder
    func onAppWillTerminate(_ action: @escaping () -> Void) -> some View {
        onNotification(.applicationWillTerminate, perform: action)
    }

    /// Perform an action on the final disappearance of a `View`.
    @ContentBuilder
    func onFinalDisappear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFinalDisappearModifier(action: action))
    }

    /// Perform an action on the first appearance of a `View`.
    @ContentBuilder
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }

    @ContentBuilder
    func onNotification<P>(_ key: Notifications.Key<P>, perform action: @escaping (P) -> Void) -> some View {
        modifier(
            OnReceiveNotificationModifier(
                key: key,
                onReceive: action
            )
        )
    }

    @ContentBuilder
    func onSceneDidEnterBackground(_ action: @escaping () -> Void) -> some View {
        onNotification(.sceneDidEnterBackground, perform: action)
    }

    @ContentBuilder
    func onScenePhase(_ phase: ScenePhase, _ action: @escaping () -> Void) -> some View {
        modifier(OnScenePhaseChangedModifier(phase: phase, action: action))
    }

    @ContentBuilder
    func onSceneWillEnterForeground(_ action: @escaping () -> Void) -> some View {
        onNotification(.sceneWillEnterForeground, perform: action)
    }

    @ContentBuilder
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

    @ContentBuilder
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

    @ContentBuilder
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

    @ContentBuilder
    func subtleShadow() -> some View {
        shadow(radius: 4, y: 2)
    }

    /// Applies the aspect ratio, corner radius, and border for the given `PosterType`
    ///
    /// Note: will not apply `subtleShadow`
    @ContentBuilder
    func posterStyle(
        _ type: PosterDisplayType,
        contentMode: ContentMode = .fill
    ) -> some View {
        modifier(PosterStyleModifier(type: type, contentMode: contentMode))
    }

    @ContentBuilder
    func preference<Key: PreferenceKey, V>(
        key: Key.Type,
        @ArrayBuilder<V> value: () -> [V]
    ) -> some View where Key.Value == [V] {
        preference(key: Key.self, value: value())
    }

    @ContentBuilder
    func scrollIfLargerThanContainer(axes: Axis.Set = .vertical, padding: CGFloat = 0, alignment: Alignment = .center) -> some View {
        modifier(ScrollIfLargerThanContainerModifier(axes: axes, padding: padding, alignment: alignment))
    }

    @ContentBuilder
    func scrollViewOffset(_ scrollViewOffset: Binding<CGFloat>) -> some View {
        modifier(ScrollViewOffsetModifier(scrollViewOffset: scrollViewOffset))
    }

    /// Perform an action as the view appears given the time interval
    /// since the view last disappeared.
    @ContentBuilder
    func sinceLastDisappear(perform action: @escaping (TimeInterval) -> Void) -> some View {
        modifier(SinceLastDisappearModifier(action: action))
    }

    @ContentBuilder
    func topBarTrailing(@ContentBuilder content: @escaping () -> some View) -> some View {
        toolbar {
            ToolbarItemGroup(
                placement: .topBarTrailing,
                content: content
            )
        }
    }

    // MARK: debug

    // Useful modifiers during development for layout

    #if DEBUG
    @ContentBuilder
    func debugBackground(_ fill: some ShapeStyle = .red.opacity(0.5)) -> some View {
        background {
            Rectangle()
                .fill(fill)
        }
    }

    @ContentBuilder
    func debugCross(_ fill: some ShapeStyle = .red) -> some View {
        debugVLine(fill)
            .debugHLine(fill)
    }

    @ContentBuilder
    func debugHLine(_ fill: some ShapeStyle) -> some View {
        overlay {
            Rectangle()
                .fill(fill)
                .frame(height: 4)
        }
    }

    @ContentBuilder
    func debugOverlay(_ fill: some ShapeStyle = .red.opacity(0.5)) -> some View {
        overlay {
            Rectangle()
                .fill(fill)
                .allowsHitTesting(false)
        }
    }

    @ContentBuilder
    func debugVLine(_ fill: some ShapeStyle) -> some View {
        overlay {
            Rectangle()
                .fill(fill)
                .frame(width: 4)
        }
    }
    #endif
}
