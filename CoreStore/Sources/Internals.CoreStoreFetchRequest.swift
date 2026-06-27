//
//  CoreStoreFetchRequest.swift
//  CoreStore
//
//  Copyright © 2019 John Rommel Estropia
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
import ObjectiveC


// MARK: - Internal

extension Internals {

    // MARK: - CoreStoreFetchRequest

    // Bugfix for NSFetchRequest messing up memory management for `affectedStores`
    // http://stackoverflow.com/questions/14396375/nsfetchedresultscontroller-crashes-in-ios-6-if-affectedstores-is-specified
    internal final class CoreStoreFetchRequest<T: NSFetchRequestResult>: NSFetchRequest<NSFetchRequestResult> {

        @nonobjc
        internal func safeAffectedStores() -> [NSPersistentStore]? {

            return self.copiedAffectedStores as! [NSPersistentStore]?
        }

        @nonobjc @inline(__always)
        internal func staticCast() -> NSFetchRequest<T> {

            return unsafeBitCast(self, to: NSFetchRequest<T>.self)
        }

        @nonobjc @inline(__always)
        internal func dynamicCast<U>() -> NSFetchRequest<U> {

            return unsafeBitCast(self, to: NSFetchRequest<U>.self)
        }


        // MARK: NSFetchRequest

        @objc dynamic
        override var affectedStores: [NSPersistentStore]? {

            get {

                return super.affectedStores
            }
            set {

                self.copiedAffectedStores = (newValue as NSArray?)?.copy() as! NSArray?
                super.affectedStores = newValue
            }
        }


        // MARK: Private

        private var copiedAffectedStores: NSArray?
        private var releaseArray: Unmanaged<NSArray>?
    }
}
