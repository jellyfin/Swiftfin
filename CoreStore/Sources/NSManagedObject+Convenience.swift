//
//  NSManagedObject+Convenience.swift
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


// MARK: - NSManagedObject

extension NSManagedObject {
    
    /**
     Exposes a `FetchableSource` that can fetch sibling objects of this `NSManagedObject` instance. This may be the `DataStack`, a `BaseDataTransaction`, the `NSManagedObjectContext` itself, or `nil` if the obejct's parent is already deallocated.
     - Warning: Future implementations may change the instance returned by this method depending on the timing or condition that `fetchSource()` was called. Do not make assumptions that the instance will be a specific instance. If the `NSManagedObjectContext` instance is desired, use the `FetchableSource.unsafeContext()` method to get the correct instance. Also, do not assume that the `fetchSource()` and `querySource()` return the same instance all the time.
     - returns: a `FetchableSource` that can fetch sibling objects of this `NSManagedObject` instance. This may be the `DataStack`, a `BaseDataTransaction`, the `NSManagedObjectContext` itself, or `nil` if the object's parent is already deallocated.
     */
    @nonobjc
    public func fetchSource() -> FetchableSource? {
        
        guard let context = self.managedObjectContext else {
            
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
        
        guard let context = self.managedObjectContext else {
            
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
     Provides a convenience wrapper for accessing `primitiveValue(forKey:)` with proper calls to `willAccessValue(forKey:)` and `didAccessValue(forKey:)`. This is useful when implementing accessor methods for transient attributes.
     
     - parameter kvcKey: the KVC key
     - returns: the primitive value for the KVC key
     */
    @nonobjc @inline(__always)
    public func getValue(
        forKvcKey kvcKey: KeyPathString
    ) -> Any? {

        self.willAccessValue(forKey: kvcKey)
        defer {
            
            self.didAccessValue(forKey: kvcKey)
        }
        return self.primitiveValue(forKey: kvcKey)
    }
    
    /**
     Provides a convenience wrapper for accessing `primitiveValue(forKey:)` with proper calls to `willAccessValue(forKey:)` and `didAccessValue(forKey:)`. This is useful when implementing accessor methods for transient attributes.
     
     - parameter kvcKey: the KVC key
     - parameter didGetValue: a closure to transform the primitive value
     - returns: the primitive value transformed by the `didGetValue` closure
     */
    @nonobjc @inline(__always)
    public func getValue<T>(
        forKvcKey kvcKey: KeyPathString,
        didGetValue: (Any?) throws(any Swift.Error) -> T
    ) rethrows -> T {

        self.willAccessValue(forKey: kvcKey)
        defer {
            
            self.didAccessValue(forKey: kvcKey)
        }
        return try didGetValue(self.primitiveValue(forKey: kvcKey))
    }
    
    /**
     Provides a convenience wrapper for accessing `primitiveValue(forKey:)` with proper calls to `willAccessValue(forKey:)` and `didAccessValue(forKey:)`. This is useful when implementing accessor methods for transient attributes.
     
     - parameter kvcKey: the KVC key
     - parameter willGetValue: called before accessing `primitiveValue(forKey:)`. Callers are allowed to cancel the access by throwing an error.
     - parameter didGetValue: a closure to transform the primitive value
     - returns: the primitive value transformed by the `didGetValue` closure
     */
    @nonobjc @inline(__always)
    public func getValue<T>(
        forKvcKey kvcKey: KeyPathString,
        willGetValue: () throws(any Swift.Error) -> Void,
        didGetValue: (Any?) throws(any Swift.Error) -> T
    ) rethrows -> T {

        self.willAccessValue(forKey: kvcKey)
        defer {
            
            self.didAccessValue(forKey: kvcKey)
        }
        try willGetValue()
        return try didGetValue(self.primitiveValue(forKey: kvcKey))
    }
    
    /**
     Provides a convenience wrapper for setting `setPrimitiveValue(_:forKey:)` with proper calls to `willChangeValue(forKey:)` and `didChangeValue(forKey:)`. This is useful when implementing mutator methods for transient attributes.
     
     - parameter value: the value to set the KVC key with
     - parameter KVCKey: the KVC key
     */
    @nonobjc @inline(__always)
    public func setValue(
        _ value: Any?,
        forKvcKey KVCKey: KeyPathString
    ) {

        self.willChangeValue(forKey: KVCKey)
        defer {
            
            self.didChangeValue(forKey: KVCKey)
        }
        self.setPrimitiveValue(value, forKey: KVCKey)
    }
    
    /**
     Provides a convenience wrapper for setting `setPrimitiveValue(_:forKey:)` with proper calls to `willChangeValue(forKey:)` and `didChangeValue(forKey:)`.
     
     - parameter value: the value to set the KVC key with
     - parameter KVCKey: the KVC key
     - parameter didSetValue: called after executing `setPrimitiveValue(forKey:)`.
     */
    @nonobjc @inline(__always)
    public func setValue(
        _ value: Any?,
        forKvcKey KVCKey: KeyPathString,
        didSetValue: () -> Void
    ) {

        self.willChangeValue(forKey: KVCKey)
        defer {
            
            self.didChangeValue(forKey: KVCKey)
        }
        self.setPrimitiveValue(value, forKey: KVCKey)
        didSetValue()
    }
    
    /**
     Provides a convenience wrapper for setting `setPrimitiveValue(_:forKey:)` with proper calls to `willChangeValue(forKey:)` and `didChangeValue(forKey:)`. This is useful when implementing mutator methods for transient attributes.
     
     - parameter value: the value to set the KVC key with
     - parameter KVCKey: the KVC key
     - parameter willSetValue: called before accessing `setPrimitiveValue(forKey:)`. Callers are allowed to cancel the mutation by throwing an error, for example, for custom validations.
     - parameter didSetValue: called after executing `setPrimitiveValue(forKey:)`.
     */
    @nonobjc @inline(__always)
    public func setValue<T>(
        _ value: T,
        forKvcKey KVCKey: KeyPathString,
        willSetValue: (T) throws(any Swift.Error) -> Any?,
        didSetValue: (Any?) -> Void = { _ in }
    ) rethrows {

        self.willChangeValue(forKey: KVCKey)
        defer {
            
            self.didChangeValue(forKey: KVCKey)
        }
        let transformedValue = try willSetValue(value)
        self.setPrimitiveValue(transformedValue, forKey: KVCKey)
        didSetValue(transformedValue)
    }
    
    /**
     Re-faults the object to use the latest values from the persistent store
     */
    @nonobjc
    public func refreshAsFault() {
        
        self.managedObjectContext?.refresh(self, mergeChanges: false)
    }
    
    /**
     Re-faults the object to use the latest values from the persistent store and merges previously pending changes back
     */
    @nonobjc
    public func refreshAndMerge() {
        
        self.managedObjectContext?.refresh(self, mergeChanges: true)
    }
}
