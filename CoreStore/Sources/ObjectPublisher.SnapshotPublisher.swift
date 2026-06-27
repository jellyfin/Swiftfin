//
//  ObjectPublisher.SnapshotPublisher.swift
//  CoreStore
//
//  Copyright © 2021 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#if canImport(Combine)
import Combine
import CoreData


// MARK: - ObjectPublisher

extension ObjectPublisher {
    
    // MARK: - SnapshotPublisher
    
    /**
     A `Publisher` that emits an `ObjectSnapshot?` whenever changes occur in the `ObjectPublisher`. The event emits `nil` if the object has been deletd.
     
     - SeeAlso: ObjectPublisher.reactive.snapshot(emitInitialValue:)
     */
    public struct SnapshotPublisher: Publisher {
        
        // MARK: Internal
        
        internal let objectPublisher: ObjectPublisher<O>
        internal let emitInitialValue: Bool
        
        
        // MARK: Publisher
        
        public typealias Output = ObjectSnapshot<O>?
        public typealias Failure = Never
        
        public func receive<S: Subscriber>(
            subscriber: S
        ) where S.Input == Output, S.Failure == Failure {

            subscriber.receive(
                subscription: ObjectSnapshotSubscription(
                    publisher: self.objectPublisher,
                    emitInitialValue: self.emitInitialValue,
                    subscriber: subscriber
                )
            )
        }
        
        
        // MARK: - ObjectSnapshotSubscriber
        
        fileprivate final class ObjectSnapshotSubscriber: Subscriber {
            
            // MARK: Subscriber
            
            typealias Failure = Never
            
            func receive(subscription: Subscription) {
                
                subscription.request(.unlimited)
            }
            
            func receive(_ input: Output) -> Subscribers.Demand {
                
                return .unlimited
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {}
        }
        
        
        // MARK: - ObjectSnapshotSubscription
        
        fileprivate final class ObjectSnapshotSubscription<S: Subscriber>: Subscription where S.Input == Output, S.Failure == Never {
            
            // MARK: FilePrivate
            
            init(
                publisher: ObjectPublisher<O>,
                emitInitialValue: Bool,
                subscriber: S
            ) {
                
                self.publisher = publisher
                self.emitInitialValue = emitInitialValue
                self.subscriber = subscriber
            }
            
            
            // MARK: Subscription
            
            func request(_ demand: Subscribers.Demand) {
                
                guard demand > 0 else {
                    
                    return
                }
                self.publisher.addObserver(
                    self,
                    notifyInitial: self.emitInitialValue,
                    { [weak self] (publisher) in
                        
                        guard
                            let self = self,
                            let subscriber = self.subscriber
                        else {
                            
                            return
                        }
                        _ = subscriber.receive(publisher.snapshot)
                    }
                )
            }
            
            
            // MARK: Cancellable
            
            func cancel() {
                
                self.subscriber = nil
                
                if Thread.isMainThread {
                    
                    self.publisher.removeObserver(self)
                }
                else {
                    
                    DispatchQueue.main.async {
                        
                        self.publisher.removeObserver(self)
                    }
                }
            }
            
            
            // MARK: Private
            
            private let publisher: ObjectPublisher<O>
            private let emitInitialValue: Bool
            private var subscriber: S?
        }
    }
}

#endif
