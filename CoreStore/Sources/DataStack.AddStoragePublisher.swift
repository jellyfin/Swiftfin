//
//  DataStack.AddStoragePublisher.swift
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


// MARK: - DataStack

extension DataStack {
    
    // MARK: - AddStoragePublisher
    
    /**
     A `Publisher` that emits a `ListSnapshot` whenever changes occur in the `ListPublisher`.
     
     - SeeAlso: DataStack.reactive.addStorage(_:)     
     */
    public struct AddStoragePublisher<Storage: LocalStorage>: Publisher {
        
        // MARK: Internal
        
        internal let dataStack: DataStack
        internal let storage: Storage
        
        
        // MARK: Publisher
        
        public typealias Output = CoreStore.MigrationProgress<Storage>
        public typealias Failure = CoreStoreError
        
        public func receive<S: Subscriber>(
            subscriber: S
        ) where S.Input == Output, S.Failure == Failure {

            subscriber.receive(
                subscription: AddStorageSubscription(
                    dataStack: self.dataStack,
                    storage: self.storage,
                    subscriber: subscriber
                )
            )
        }
        
        
        // MARK: - AddStorageSubscriber
        
        fileprivate final class AddStorageSubscriber: Subscriber {
            
            // MARK: Subscriber
            
            typealias Failure = CoreStoreError
            
            func receive(subscription: Subscription) {
                
                subscription.request(.unlimited)
            }
            
            func receive(_ input: Output) -> Subscribers.Demand {
                
                return .unlimited
            }
            
            func receive(completion: Subscribers.Completion<Failure>) {}
        }
        
        
        // MARK: - AddStorageSubscription
        
        fileprivate final class AddStorageSubscription<S: Subscriber>: Subscription where S.Input == Output, S.Failure == CoreStoreError {
            
            // MARK: FilePrivate
            
            fileprivate init(
                dataStack: DataStack,
                storage: Storage,
                subscriber: S
            ) {
                
                self.dataStack = dataStack
                self.storage = storage
                self.subscriber = subscriber
            }
            
            
            // MARK: Subscription
            
            func request(_ demand: Subscribers.Demand) {
                
                guard demand > 0 else {
                    
                    return
                }
                var progress: Progress? = nil
                progress = self.dataStack.addStorage(
                    self.storage,
                    completion: { [weak self] result in
                        
                        progress?.setProgressHandler(nil)
                        
                        guard
                            let self = self,
                            let subscriber = self.subscriber
                        else {
                            
                            return
                        }
                        switch result {
                        
                        case .success(let storage):
                            _ = subscriber.receive(
                                .finished(
                                    storage: storage,
                                    migrationRequired: progress != nil
                                )
                            )
                            subscriber.receive(
                                completion: .finished
                            )
                            
                        case .failure(let error):
                            subscriber.receive(
                                completion: .failure(error)
                            )
                        }
                    }
                )
                if let progress = progress {
                    
                    progress.setProgressHandler { [weak self] progress in
                        
                        guard
                            let self = self,
                            let subscriber = self.subscriber
                        else {
                            
                            return
                        }
                        _ = subscriber.receive(
                            .migrating(
                                storage: self.storage,
                                progressObject: progress
                            )
                        )
                    }
                }
            }
            
            
            // MARK: Cancellable
            
            func cancel() {
                
                self.subscriber = nil
            }
            
            
            // MARK: Private
            
            private let dataStack: DataStack
            private let storage: Storage
            private var subscriber: S?
        }
    }
}

#endif
