//
//  Tweak.swift
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


// MARK: - Tweak

/**
 The `Tweak` clause allows fine-tuning the `NSFetchRequest` for a fetch or query.
 Sample usage:
 ```
 let employees = transaction.fetchAll(
     From<MyPersonEntity>(),
     Tweak { (fetchRequest) -> Void in
         fetchRequest.includesPendingChanges = false
         fetchRequest.fetchLimit = 5
     }
 )
 ```
 */
public struct Tweak: FetchClause, QueryClause, DeleteClause {
    
    /**
     The block to customize the `NSFetchRequest`
     */
    public let closure: (_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> Void
    
    /**
     Initializes a `Tweak` clause with a closure where the `NSFetchRequest` may be configured.
     
     - Important: `Tweak`'s closure is executed only just before the fetch occurs, so make sure that any values captured by the closure is not prone to race conditions. Also, some utilities (such as `ListMonitor`s) may keep `FetchClause`s in memory and may thus introduce retain cycles if reference captures are not handled properly.
     - parameter closure: the block to customize the `NSFetchRequest`
     */
    public init(_ closure: @escaping (_ fetchRequest: NSFetchRequest<NSFetchRequestResult>) -> Void) {
        
        self.closure = closure
    }
    
    
    // MARK: FetchClause, QueryClause, DeleteClause
    
    public func applyToFetchRequest<ResultType>(_ fetchRequest: NSFetchRequest<ResultType>) {
        
        self.closure(fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
    }
}
