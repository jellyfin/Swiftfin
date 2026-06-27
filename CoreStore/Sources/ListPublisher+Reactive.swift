//
//  ListPublisher+Reactive.swift
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


// MARK: - ListPublisher

extension ListPublisher {
    
    // MARK: Public
    
    /**
     Combine utilities for the `ListPublisher` are exposed through this namespace
     */
    public var reactive: ListPublisher.ReactiveNamespace {
        
        return .init(self)
    }
    
    
    // MARK: - ReactiveNamespace
    
    /**
     Combine utilities for the `ListPublisher` are exposed through this namespace. Extend this type if you need to add other Combine Publisher utilities for `ListPublisher`.
     */
    public struct ReactiveNamespace {
        
        // MARK: Public
        
        /**
         The `ListPublisher` instance
         */
        public let base: ListPublisher
        
        
        // MARK: Internal
        
        internal init(_ base: ListPublisher) {
            
            self.base = base
        }
    }
}


// MARK: - ListPublisher.ReactiveNamespace

extension ListPublisher.ReactiveNamespace {

    // MARK: Public
    
    /**
     Returns a `Publisher` that emits a `ListSnapshot` whenever changes occur in the `ListPublisher`
     ```
     listPublisher.reactive
         .snapshot(emitInitialValue: true)
         .sink(
             receiveCompletion: { result in
                 // ...
             },
             receiveValue: { (listSnapshot) in
                 dataSource.apply(
                     listSnapshot,
                     animatingDifferences: true
                 )
             }
         )
         .store(in: &cancellables)
     ```
     - parameter emitInitialValue: If `true`, the current value is immediately emitted to the first subscriber. If `false`, the event fires only starting the next `ListSnapshot` update.
     - returns: A `Publisher` that emits a `ListSnapshot` whenever changes occur in the `ListPublisher`.
     */
    public func snapshot(
        emitInitialValue: Bool = true
    ) -> ListPublisher.SnapshotPublisher {

        return .init(
            listPublisher: self.base,
            emitInitialValue: emitInitialValue
        )
    }
}

#endif
