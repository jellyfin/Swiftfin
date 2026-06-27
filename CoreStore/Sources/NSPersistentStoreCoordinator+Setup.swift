//
//  NSPersistentStoreCoordinator+Setup.swift
//  CoreStore
//
//  Copyright © 2018 John Rommel Estropia. All rights reserved.
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


// MARK: - NSPersistentStoreCoordinator

extension NSPersistentStoreCoordinator {
    
    @nonobjc
    internal func performAsynchronously(
        _ closure: @escaping () -> Void
    ) {

        self.perform(closure)
    }
    
    @nonobjc
    internal func performSynchronously<T>(
        _ closure: @escaping () -> T
    ) -> T {

        var result: T?
        self.performAndWait {
            
            result = closure()
        }
        return result!
    }
    
    @nonobjc
    internal func performSynchronously<T>(
        _ closure: @escaping () throws(any Swift.Error) -> T
    ) throws(CoreStoreError) -> T {

        var closureError: (any Swift.Error)?
        var result: T?
        self.performAndWait {
            
            do {
                
                result = try closure()
            }
            catch {
                
                closureError = error
            }
        }
        if let closureError = closureError {
            
            throw CoreStoreError(closureError)
        }
        return result!
    }

    @nonobjc
    internal func addPersistentStoreSynchronously(
        _ storeType: String,
        configuration: ModelConfiguration,
        URL storeURL: URL?,
        options: [AnyHashable: Any]?
    ) throws(CoreStoreError) -> NSPersistentStore {

        return try self.performSynchronously {

            return try self.addPersistentStore(
                ofType: storeType,
                configurationName: configuration,
                at: storeURL,
                options: options
            )
        }
    }
}
