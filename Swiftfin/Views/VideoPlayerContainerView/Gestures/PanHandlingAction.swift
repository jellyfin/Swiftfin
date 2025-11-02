//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol _PanHandlingAction {
    associatedtype Value: Comparable & AdditiveArithmetic

    typealias OnChangeAction = (
        _ startState: _PanStartHandlingState<Value>,
        _ panState: _PanHandlingState,
        _ containerState: VideoPlayerContainerState
    ) -> Void

    var startState: _PanStartHandlingState<Value> { get set }
    var startValue: (VideoPlayerContainerState) -> Value { get set }

    var onChange: OnChangeAction { get }
}

struct _PanHandlingState {
    let translation: CGPoint
    let velocity: CGPoint
    let location: CGPoint
    let unitPoint: UnitPoint
    let gestureState: UIGestureRecognizer.State
}

struct _PanStartHandlingState<Value: Comparable & AdditiveArithmetic> {
    let direction: Direction
    let location: CGPoint
    let startedWithOverlay: Bool
    let value: Value
}

struct PanHandlingAction<Value: Comparable & AdditiveArithmetic>: _PanHandlingAction {

    typealias OnChangeAction = (
        _ startState: _PanStartHandlingState<Value>,
        _ panState: _PanHandlingState,
        _ containerState: VideoPlayerContainerState
    ) -> Void

    var startState: _PanStartHandlingState<Value> = .init(
        direction: .all,
        location: .zero,
        startedWithOverlay: false,
        value: .zero
    )
    var startValue: (VideoPlayerContainerState) -> Value
    let onChange: OnChangeAction

    init(
        startValue: Value,
        onChange: @escaping OnChangeAction
    ) {
        self.startValue = { _ in startValue }
        self.onChange = onChange
    }

    init(
        startValue: @escaping (VideoPlayerContainerState) -> Value,
        onChange: @escaping OnChangeAction
    ) {
        self.startValue = startValue
        self.onChange = onChange
    }
}
