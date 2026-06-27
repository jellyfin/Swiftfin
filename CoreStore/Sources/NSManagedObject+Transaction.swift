//
//  NSManagedObject+Transaction.swift
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
     Returns this object's parent `UnsafeDataTransaction` instance if it was created from one. Returns `nil` if the parent transaction is either an `AsynchronousDataTransaction` or a `SynchronousDataTransaction`, or if the object is not managed by CoreStore.
     
     When using an `UnsafeDataTransaction` and passing around a temporary object, you can use this property to execute fetches and updates to the transaction without having to pass around both the object and the transaction instances.
     
     - Important: The internal reference to the transaction is `weak`, and it is still the developer's responsibility to retain a strong reference to the `UnsafeDataTransaction`.
     */
    @nonobjc
    public var unsafeDataTransaction: UnsafeDataTransaction? {
        
        return self.managedObjectContext?.parentTransaction as? UnsafeDataTransaction
    }
}
