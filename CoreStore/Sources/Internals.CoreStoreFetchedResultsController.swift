//
//  CoreStoreFetchedResultsController.swift
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


// MARK: - Internals

extension Internals {
    
    // MARK: - CoreStoreFetchedResultsController
    
    internal final class CoreStoreFetchedResultsController: NSFetchedResultsController<NSManagedObject> {
        
        // MARK: Internal
        
        @nonobjc
        internal let typedFetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>
        
        @nonobjc
        internal convenience init<O>(dataStack: DataStack, fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>, from: From<O>, sectionBy: SectionBy<O>? = nil, applyFetchClauses: @escaping (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void) {
            
            self.init(
                context: dataStack.mainContext,
                fetchRequest: fetchRequest,
                from: from,
                sectionBy: sectionBy,
                applyFetchClauses: applyFetchClauses
            )
        }
        
        @nonobjc
        internal init<O>(context: NSManagedObjectContext, fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>, from: From<O>, sectionBy: SectionBy<O>? = nil, applyFetchClauses: @escaping (_ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>) -> Void) {
            
            _ = try? from.applyToFetchRequest(
                fetchRequest,
                context: context,
                applyAffectedStores: false
            )
            applyFetchClauses(fetchRequest)
            
            self.typedFetchRequest = fetchRequest
            self.reapplyAffectedStores = { fetchRequest, context in
                
                try from.applyAffectedStoresForFetchedRequest(fetchRequest, context: context)
            }
            
            super.init(
                fetchRequest: fetchRequest.staticCast(),
                managedObjectContext: context,
                sectionNameKeyPath: sectionBy?.sectionKeyPath,
                cacheName: nil
            )
        }
        
        @nonobjc
        internal func performFetchFromSpecifiedStores() throws(any Swift.Error) {

            try self.reapplyAffectedStores(self.typedFetchRequest, self.managedObjectContext)
            try self.performFetch()

            if case let delegate as FetchedDiffableDataSourceSnapshotDelegate = self.delegate {

                delegate.initialFetch()
            }
        }
        
        @nonobjc
        internal func dynamicCast<U>() -> NSFetchedResultsController<U> {
            
            return unsafeBitCast(self, to: NSFetchedResultsController<U>.self)
        }
        
        deinit {
            
            self.delegate = nil
        }
        
        
        // MARK: Private
        
        @nonobjc
        private let reapplyAffectedStores: (
            _ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObject>,
            _ context: NSManagedObjectContext
        ) throws(any Swift.Error) -> Void
    }
}
