//
//  ObjectPublisher+Reactive.swift
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
    
    // MARK: Public
    
    /**
     Combine utilities for the `ObjectPublisher` are exposed through this namespace
     */
    public var reactive: ObjectPublisher.ReactiveNamespace {
        
        return .init(self)
    }
    
    
    // MARK: - ReactiveNamespace
    
    /**
     Combine utilities for the `ObjectPublisher` are exposed through this namespace. Extend this type if you need to add other Combine Publisher utilities for `ObjectPublisher`.
     */
    @dynamicMemberLookup
    public struct ReactiveNamespace {
        
        // MARK: Public
        
        /**
         The `ObjectPublisher` instance
         */
        public let base: ObjectPublisher
        
        
        // MARK: Internal
        
        internal init(_ base: ObjectPublisher) {
            
            self.base = base
        }
    }
}


// MARK: - ObjectPublisher.ReactiveNamespace

extension ObjectPublisher.ReactiveNamespace {

    // MARK: Public
    
    /**
     Returns a `Publisher` that emits an `ObjectSnapshot?` whenever changes occur in the `ObjectPublisher`. The event emits `nil` if the object has been deletd.
     ```
     objectPublisher.reactive
         .snapshot(emitInitialValue: true)
         .sink(
             receiveCompletion: { result in
                 // ...
             },
             receiveValue: { (objectSnapshot) in
                 tableViewCell.setObject(objectSnapshot)
             }
         )
         .store(in: &tableViewCell.cancellables)
     ```
     - parameter emitInitialValue: If `true`, the current value is immediately emitted to the first subscriber. If `false`, the event fires only starting the next `ObjectSnapshot` update.
     - returns: A `Publisher` that emits an `ObjectSnapshot?` whenever changes occur in the `ObjectPublisher`. The event emits `nil` if the object has been deletd.
     */
    public func snapshot(
        emitInitialValue: Bool = true
    ) -> ObjectPublisher.SnapshotPublisher {

        return .init(
            objectPublisher: self.base,
            emitInitialValue: emitInitialValue
        )
    }
}


// MARK: - ObjectPublisher.ReactiveNamespace where O: NSManagedObject

extension ObjectPublisher.ReactiveNamespace where O: NSManagedObject {

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<V: AllowedObjectiveCKeyPathValue>(
        dynamicMember member: KeyPath<O, V>
    ) -> some Publisher {

        return self
            .snapshot(emitInitialValue: true)
            .map({ $0?[dynamicMember: member] })
    }
}


// MARK: - ObjectPublisher.ReactiveNamespace where O: CoreStoreObject

extension ObjectPublisher.ReactiveNamespace where O: CoreStoreObject {

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Stored<V>>
    ) -> some Publisher {

        return self
            .snapshot(emitInitialValue: true)
            .map({ $0?[dynamicMember: member] })
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Virtual<V>>
    ) -> some Publisher {

        return self
            .snapshot(emitInitialValue: true)
            .map({ $0?[dynamicMember: member] })
    }

    /**
     Returns the value for the property identified by a given key.
     */
    public subscript<OBase, V>(
        dynamicMember member: KeyPath<O, FieldContainer<OBase>.Coded<V>>
    ) -> some Publisher {

        return self
            .snapshot(emitInitialValue: true)
            .map({ $0?[dynamicMember: member] })
    }
}

#endif
