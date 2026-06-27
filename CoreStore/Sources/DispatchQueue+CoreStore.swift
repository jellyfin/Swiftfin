//
//  DispatchQueue+CoreStore.swift
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


// MARK: - DispatchQueue

extension DispatchQueue {
    
    @nonobjc @inline(__always)
    internal static func serial(
        _ label: String,
        qos: DispatchQoS
    ) -> DispatchQueue {

        return DispatchQueue(
            label: label,
            qos: qos,
            attributes: [],
            autoreleaseFrequency: .inherit,
            target: nil
        )
    }
    
    @nonobjc @inline(__always)
    internal static func concurrent(
        _ label: String,
        qos: DispatchQoS
    ) -> DispatchQueue {

        return DispatchQueue(
            label: label,
            qos: qos,
            attributes: .concurrent,
            autoreleaseFrequency: .inherit,
            target: nil
        )
    }
    
    @nonobjc
    internal func cs_isCurrentExecutionContext() -> Bool {
        
        enum Static {
            
            static let specificKey = DispatchSpecificKey<ObjectIdentifier>()
        }
        
        let specific = ObjectIdentifier(self)
        
        self.setSpecific(key: Static.specificKey, value: specific)
        return DispatchQueue.getSpecific(key: Static.specificKey) == specific
    }
    
    @nonobjc @inline(__always)
    internal func cs_sync<T>(
        _ closure: () -> T
    ) -> T {

        return self.sync { autoreleasepool(invoking: closure) }
    }

    @nonobjc @inline(__always)
    internal func cs_sync<T>(
        _ closure: () throws(CoreStoreError) -> T
    ) throws(CoreStoreError) -> T {

        do {

            return try self.sync { try autoreleasepool(invoking: closure) }
        }
        catch {

            throw CoreStoreError(error)
        }
    }

    @nonobjc @inline(__always)
    internal func cs_async(
        _ closure: @escaping () -> Void
    ) {

        self.async { autoreleasepool(invoking: closure) }
    }
    
    @nonobjc @inline(__always)
    internal func cs_barrierSync<T>(
        _ closure: () throws(any Swift.Error) -> T
    ) rethrows -> T {

        return try self.sync(flags: .barrier) { try autoreleasepool(invoking: closure) }
    }
    
    @nonobjc @inline(__always)
    internal func cs_barrierAsync(
        _ closure: @escaping () -> Void
    ) {

        self.async(flags: .barrier) { autoreleasepool(invoking: closure) }
    }
    
    
    // MARK: Private
}
