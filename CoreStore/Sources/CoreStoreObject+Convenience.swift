//
//  CoreStoreObject+Convenience.swift
//  CoreStore
//
//  Copyright © 2018 John Rommel Estropia
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

import Foundation
import CoreData


// MARK: - CoreStoreObject

extension CoreStoreObject {
    
    /**
     Exposes a `FetchableSource` that can fetch sibling objects of this `CoreStoreObject` instance. This may be the `DataStack`, a `BaseDataTransaction`, the `NSManagedObjectContext` itself, or `nil` if the obejct's parent is already deallocated.
     - Warning: Future implementations may change the instance returned by this method depending on the timing or condition that `fetchSource()` was called. Do not make assumptions that the instance will be a specific instance. If the `NSManagedObjectContext` instance is desired, use the `FetchableSource.unsafeContext()` method to get the correct instance. Also, do not assume that the `fetchSource()` and `querySource()` return the same instance all the time.
     - returns: a `FetchableSource` that can fetch sibling objects of this `CoreStoreObject` instance. This may be the `DataStack`, a `BaseDataTransaction`, the `NSManagedObjectContext` itself, or `nil` if the object's parent is already deallocated.
     */
    @nonobjc
    public func fetchSource() -> FetchableSource? {
        
        guard let context = self.rawObject!.managedObjectContext else {
            
            return nil
        }
        if context.isTransactionContext {
            
            return context.parentTransaction
        }
        if context.isDataStackContext {
            
            return context.parentStack
        }
        return context
    }
    
    /**
     Exposes a `QueryableSource` that can query attributes and aggregate values. This may be the `DataStack`, a `BaseDataTransaction`, the `NSManagedObjectContext` itself, or `nil` if the obejct's parent is already deallocated.
     - Warning: Future implementations may change the instance returned by this method depending on the timing or condition that `querySource()` was called. Do not make assumptions that the instance will be a specific instance. If the `NSManagedObjectContext` instance is desired, use the `QueryableSource.unsafeContext()` method to get the correct instance. Also, do not assume that the `fetchSource()` and `querySource()` return the same instance all the time.
     - returns: a `QueryableSource` that can query attributes and aggregate values. This may be the `DataStack`, a `BaseDataTransaction`, the `NSManagedObjectContext` itself, or `nil` if the object's parent is already deallocated.
     */
    @nonobjc
    public func querySource() -> QueryableSource? {
        
        guard let context = self.rawObject!.managedObjectContext else {
            
            return nil
        }
        if context.isTransactionContext {
            
            return context.parentTransaction
        }
        if context.isDataStackContext {
            
            return context.parentStack
        }
        return context
    }
    
    /**
     Re-faults the object to use the latest values from the persistent store
     */
    @nonobjc
    public func refreshAsFault() {
        
        let rawObject = self.rawObject!
        rawObject.managedObjectContext?.refresh(rawObject, mergeChanges: false)
    }
    
    /**
     Re-faults the object to use the latest values from the persistent store and merges previously pending changes back
     */
    @nonobjc
    public func refreshAndMerge() {
        
        let rawObject = self.rawObject!
        rawObject.managedObjectContext?.refresh(rawObject, mergeChanges: true)
    }
}
