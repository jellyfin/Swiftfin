//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation

// Reactive-like state handling for non-SwiftUI views

public protocol State {
    associatedtype EventType
    mutating func respond(to event: EventType)
}

public protocol Subscriber: AnyObject {}

private class Wrapper<T: State> {
    weak var subscriber: Subscriber?
    var update: (T) -> Void
    
    init<S: Subscriber>(subscriber: S, update: @escaping (S) -> ((T) -> Void)) {
        self.subscriber = subscriber
        self.update = { [weak subscriber] state in
            guard let subscriber = subscriber else { return }
            update(subscriber)(state)
        }
    }
    
    var subscriberStillExists: Bool {
        return subscriber != nil
    }
}

public class Core<T: State> {
    private var wrappers = [Wrapper<T>]()
    public private(set) var state: T
    public let queue: OperationQueue = Core._queue()
    public private(set) var lastEvent: T.EventType?
    private static func _queue() -> OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }
    
    public func addSubscriber<S: Subscriber>(subscriber: S, update: @escaping (S) -> ((T) -> Void)) {
        let wrapper = Wrapper(subscriber: subscriber, update: update)
        DispatchQueue.main.async {
            wrapper.update(self.state)
        }
        wrappers.append(wrapper)
    }
    
    public init(state: T) {
        self.state = state
    }
    
    public func fire<E>(_ event: E) where T.EventType == E {
        queue.addOperation {
            self.lastEvent = event
            self.state.respond(to: event)
            self.updateSubscribers()
        }
    }
    
    func updateSubscribers() {
        DispatchQueue.main.async { [weak self] in
            self?.updateOnMain()
        }
    }
    
    private func updateOnMain() {
        wrappers = wrappers.filter { $0.subscriberStillExists }
        for wrapper in wrappers {
            wrapper.update(state)
        }
    }
}
