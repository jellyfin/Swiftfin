//
//  ImportableObject.swift
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


// MARK: - ImportableObject

/**
 `NSManagedObject` and `CoreStoreObject` subclasses that conform to the `ImportableObject` protocol can be imported from a specified `ImportSource`. This allows transactions to create and insert instances this way:
 ```
 class Person: NSManagedObject, ImportableObject {
     typealias ImportSource = NSDictionary
     // ...
 }
 
 dataStack.perform(
     asynchronous: { (transaction) -> Void in
         let json: NSDictionary = // ...
         let person = try transaction.importObject(
             Into<Person>(),
             source: json
         )
         // ...
     },
     completion: { (result) in
         // ...
     }
 )
 ```
 */
public protocol ImportableObject: DynamicObject {
    
    /**
     The data type for the import source. This is most commonly an json type, `NSDictionary`, or another external source such as `NSUserDefaults`.
     */
    associatedtype ImportSource
    
    /**
     Return `true` if an object should be created from `source`. Return `false` to ignore and skip `source`. The default implementation returns `true`.
     
     - parameter source: the object to import from
     - parameter transaction: the transaction that invoked the import. Use the transaction to fetch or create related objects if needed.
     - returns: `true` if an object should be created from `source`. Return `false` to ignore.
     */
    static func shouldInsert(
        from source: ImportSource,
        in transaction: BaseDataTransaction
    ) -> Bool

    /**
     Implements the actual importing of data from `source`. Implementers should pull values from `source` and assign them to the receiver's attributes. Note that throwing from this method will cause subsequent imports that are part of the same `importObjects(:sourceArray:)` call to be cancelled.
     
     - parameter source: the object to import from
     - parameter transaction: the transaction that invoked the import. Use the transaction to fetch or create related objects if needed.
     */
    func didInsert(
        from source: ImportSource,
        in transaction: BaseDataTransaction
    ) throws(any Swift.Error)
}


// MARK: - ImportableObject (Default Implementations)

extension ImportableObject {
    
    public static func shouldInsert(
        from source: ImportSource,
        in transaction: BaseDataTransaction
    ) -> Bool {

        return true
    }
}
