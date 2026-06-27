//
//  NSManagedObjectContext+Querying.swift
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


// MARK: - NSManagedObjectContext

extension NSManagedObjectContext: FetchableSource, QueryableSource {
    
    // MARK: FetchableSource
    
    @nonobjc
    public func fetchExisting<O: DynamicObject>(
        _ object: O
    ) -> O? {

        let rawObject = object.cs_toRaw()
        if rawObject.objectID.isTemporaryID {
            
            do {
                
                try withExtendedLifetime(self) { (context: NSManagedObjectContext) -> Void in
                    
                    try context.obtainPermanentIDs(for: [rawObject])
                }
            }
            catch {
                
                Internals.log(
                    CoreStoreError(error),
                    "Failed to obtain permanent ID for object."
                )
                return nil
            }
        }
        do {
            
            let existingRawObject = try self.existingObject(with: rawObject.objectID)
            if existingRawObject === rawObject {
                
                return object
            }
            return object.runtimeType().cs_fromRaw(object: existingRawObject)
        }
        catch {
            
            Internals.log(
                CoreStoreError(error),
                "Failed to load existing \(Internals.typeName(object)) in context."
            )
            return nil
        }
    }
    
    @nonobjc
    public func fetchExisting<O: DynamicObject>(
        _ objectID: NSManagedObjectID
    ) -> O? {

        do {
            
            let existingObject = try self.existingObject(with: objectID)
            return O.cs_fromRaw(object: existingObject)
        }
        catch _ {
            
            return nil
        }
    }
    
    @nonobjc
    public func fetchExisting<O: DynamicObject, S: Sequence>(
        _ objects: S
    ) -> [O] where S.Iterator.Element == O {

        return objects.compactMap({ self.fetchExisting($0.cs_id()) })
    }
    
    @nonobjc
    public func fetchExisting<O: DynamicObject, S: Sequence>(
        _ objectIDs: S
    ) -> [O] where S.Iterator.Element == NSManagedObjectID {

        return objectIDs.compactMap({ self.fetchExisting($0) })
    }
    
    @nonobjc
    public func fetchOne<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> O? {

        return try self.fetchOne(from, fetchClauses)
    }
    
    @nonobjc
    public func fetchOne<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> O? {

        let fetchRequest = Internals.CoreStoreFetchRequest<NSManagedObject>()
        try from.applyToFetchRequest(fetchRequest, context: self)
        
        fetchRequest.fetchLimit = 1
        fetchRequest.resultType = .managedObjectResultType
        fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

        return try self.fetchOne(fetchRequest).flatMap(from.entityClass.cs_fromRaw)
    }
    
    @nonobjc
    public func fetchOne<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> B.ObjectType? {

        return try self.fetchOne(
            clauseChain.from,
            clauseChain.fetchClauses
        )
    }
    
    @nonobjc
    public func fetchAll<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> [O] {

        return try self.fetchAll(from, fetchClauses)
    }
    
    @nonobjc
    public func fetchAll<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> [O] {

        let fetchRequest = Internals.CoreStoreFetchRequest<NSManagedObject>()
        try from.applyToFetchRequest(fetchRequest, context: self)
        
        fetchRequest.fetchLimit = 0
        fetchRequest.resultType = .managedObjectResultType
        fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

        let entityClass = from.entityClass
        return try self.fetchAll(fetchRequest).map(entityClass.cs_fromRaw)
    }
    
    @nonobjc
    public func fetchAll<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> [B.ObjectType] {

        return try self.fetchAll(
            clauseChain.from,
            clauseChain.fetchClauses
        )
    }
    
    @nonobjc
    public func fetchCount<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> Int {

        return try self.fetchCount(from, fetchClauses)
    }
    
    @nonobjc
    public func fetchCount<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> Int {

        let fetchRequest = Internals.CoreStoreFetchRequest<NSNumber>()
        try from.applyToFetchRequest(fetchRequest, context: self)

        fetchRequest.resultType = .countResultType
        fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

        return try self.fetchCount(fetchRequest)
    }
    
    @nonobjc
    public func fetchCount<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> Int {

        return try self.fetchCount(
            clauseChain.from,
            clauseChain.fetchClauses
        )
    }
    
    @nonobjc
    public func fetchObjectID<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> NSManagedObjectID? {

        return try self.fetchObjectID(from, fetchClauses)
    }
    
    @nonobjc
    public func fetchObjectID<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> NSManagedObjectID? {

        let fetchRequest = Internals.CoreStoreFetchRequest<NSManagedObjectID>()
        try from.applyToFetchRequest(fetchRequest, context: self)
        
        fetchRequest.fetchLimit = 1
        fetchRequest.resultType = .managedObjectIDResultType
        fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

        return try self.fetchObjectID(fetchRequest)
    }

    @nonobjc
    public func fetchObjectID<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> NSManagedObjectID? {

        return try self.fetchObjectID(
            clauseChain.from,
            clauseChain.fetchClauses
        )
    }
    
    @nonobjc
    public func fetchObjectIDs<O>(
        _ from: From<O>,
        _ fetchClauses: FetchClause...
    ) throws(CoreStoreError) -> [NSManagedObjectID] {

        return try self.fetchObjectIDs(from, fetchClauses)
    }
    
    @nonobjc
    public func fetchObjectIDs<O>(
        _ from: From<O>,
        _ fetchClauses: [FetchClause]
    ) throws(CoreStoreError) -> [NSManagedObjectID] {

        let fetchRequest = Internals.CoreStoreFetchRequest<NSManagedObjectID>()
        try from.applyToFetchRequest(fetchRequest, context: self)
        
        fetchRequest.fetchLimit = 0
        fetchRequest.resultType = .managedObjectIDResultType
        fetchClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

        return try self.fetchObjectIDs(fetchRequest)
    }

    @nonobjc
    public func fetchObjectIDs<B: FetchChainableBuilderType>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> [NSManagedObjectID] {

        return try self.fetchObjectIDs(
            clauseChain.from,
            clauseChain.fetchClauses
        )
    }
    
    @nonobjc
    internal func fetchObjectIDs(
        _ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObjectID>
    ) throws(CoreStoreError) -> [NSManagedObjectID] {

        var fetchResults: [NSManagedObjectID]?
        var fetchError: Error?
        self.performAndWait {
            
            do {
                
                fetchResults = try self.fetch(fetchRequest.dynamicCast())
            }
            catch {
                
                fetchError = error
            }
        }
        if let fetchResults = fetchResults {

            return fetchResults
        }
        let coreStoreError = CoreStoreError(fetchError)
        Internals.log(
            coreStoreError,
            "Failed executing fetch request."
        )
        throw coreStoreError
    }
    
    
    // MARK: QueryableSource
    
    @nonobjc
    public func queryValue<O, U: QueryableAttributeType>(
        _ from: From<O>,
        _ selectClause: Select<O, U>,
        _ queryClauses: QueryClause...
    ) throws(CoreStoreError) -> U? {

        return try self.queryValue(from, selectClause, queryClauses)
    }
    
    @nonobjc
    public func queryValue<O, U: QueryableAttributeType>(
        _ from: From<O>,
        _ selectClause: Select<O, U>,
        _ queryClauses: [QueryClause]
    ) throws(CoreStoreError) -> U? {

        let fetchRequest = Internals.CoreStoreFetchRequest<NSDictionary>()
        try from.applyToFetchRequest(fetchRequest, context: self)
        
        fetchRequest.fetchLimit = 0
        
        selectClause.applyToFetchRequest(fetchRequest.staticCast())
        queryClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

        return try self.queryValue(selectClause.selectTerms, fetchRequest: fetchRequest)
    }
    
    @nonobjc
    public func queryValue<B>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> B.ResultType? where B: QueryChainableBuilderType, B.ResultType: QueryableAttributeType {

        return try self.queryValue(
            clauseChain.from,
            clauseChain.select,
            clauseChain.queryClauses
        )
    }
    
    @nonobjc
    public func queryAttributes<O>(
        _ from: From<O>,
        _ selectClause: Select<O, NSDictionary>,
        _ queryClauses: QueryClause...
    ) throws(CoreStoreError) -> [[String: Any]] {

        return try self.queryAttributes(from, selectClause, queryClauses)
    }
    
    @nonobjc
    public func queryAttributes<O>(
        _ from: From<O>,
        _ selectClause: Select<O, NSDictionary>,
        _ queryClauses: [QueryClause]
    ) throws(CoreStoreError) -> [[String: Any]] {

        let fetchRequest = Internals.CoreStoreFetchRequest<NSDictionary>()
        try from.applyToFetchRequest(fetchRequest, context: self)
        
        fetchRequest.fetchLimit = 0
        
        selectClause.applyToFetchRequest(fetchRequest.staticCast())
        queryClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

        return try self.queryAttributes(fetchRequest)
    }
    
    public func queryAttributes<B>(
        _ clauseChain: B
    ) throws(CoreStoreError) -> [[String : Any]] where B : QueryChainableBuilderType, B.ResultType == NSDictionary {

        return try self.queryAttributes(
            clauseChain.from,
            clauseChain.select,
            clauseChain.queryClauses
        )
    }
    
    
    // MARK: FetchableSource, QueryableSource
    
    @nonobjc
    public func unsafeContext() -> NSManagedObjectContext {
        
        return self
    }
    
    
    // MARK: Deleting
    
    @nonobjc
    internal func deleteAll<O>(
        _ from: From<O>,
        _ deleteClauses: [FetchClause]
    ) throws(CoreStoreError) -> Int {

        let fetchRequest = Internals.CoreStoreFetchRequest<NSManagedObject>()
        try from.applyToFetchRequest(fetchRequest, context: self)
        
        fetchRequest.fetchLimit = 0
        fetchRequest.resultType = .managedObjectResultType
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.includesPropertyValues = false
        deleteClauses.forEach { $0.applyToFetchRequest(fetchRequest) }

        return try self.deleteAll(fetchRequest)
    }
}


// MARK: - NSManagedObjectContext (Internal)

extension NSManagedObjectContext {
    
    // MARK: Fetching
    
    @nonobjc
    internal func fetchOne<O: NSManagedObject>(
        _ fetchRequest: Internals.CoreStoreFetchRequest<O>
    ) throws(CoreStoreError) -> O? {

        var fetchResults: [O]?
        var fetchError: (any Swift.Error)?
        self.performAndWait {
            
            do {
                
                fetchResults = try self.fetch(fetchRequest.staticCast())
            }
            catch {
                
                fetchError = error
            }
        }
        if let fetchResults = fetchResults {

            return fetchResults.first
        }
        let coreStoreError = CoreStoreError(fetchError)
        Internals.log(
            coreStoreError,
            "Failed executing fetch request."
        )
        throw coreStoreError
    }
    
    @nonobjc
    internal func fetchAll<O: NSManagedObject>(
        _ fetchRequest: Internals.CoreStoreFetchRequest<O>
    ) throws(CoreStoreError) -> [O] {

        var fetchResults: [O]?
        var fetchError: (any Swift.Error)?
        self.performAndWait {
            
            do {
                
                fetchResults = try self.fetch(fetchRequest.staticCast())
            }
            catch {
                
                fetchError = error
            }
        }
        if let fetchResults = fetchResults {

            return fetchResults
        }
        let coreStoreError = CoreStoreError(fetchError)
        Internals.log(
            coreStoreError,
            "Failed executing fetch request."
        )
        throw coreStoreError
    }
    
    @nonobjc
    internal func fetchCount(
        _ fetchRequest: Internals.CoreStoreFetchRequest<NSNumber>
    ) throws(CoreStoreError) -> Int {

        var count = 0
        var countError: (any Swift.Error)?
        self.performAndWait {
            
            do {
                
                count = try self.count(for: fetchRequest.staticCast())
            }
            catch {
                
                countError = error
            }
        }
        if count == NSNotFound {

            let coreStoreError = CoreStoreError(countError)
            Internals.log(
                coreStoreError,
                "Failed executing count request."
            )
            throw coreStoreError
        }
        return count
    }
    
    @nonobjc
    internal func fetchObjectID(
        _ fetchRequest: Internals.CoreStoreFetchRequest<NSManagedObjectID>
    ) throws(CoreStoreError) -> NSManagedObjectID? {

        var fetchResults: [NSManagedObjectID]?
        var fetchError: (any Swift.Error)?
        self.performAndWait {
            
            do {
                
                fetchResults = try self.fetch(fetchRequest.staticCast())
            }
            catch {
                
                fetchError = error
            }
        }
        if let fetchResults = fetchResults {

            return fetchResults.first
        }
        let coreStoreError = CoreStoreError(fetchError)
        Internals.log(
            coreStoreError,
            "Failed executing fetch request."
        )
        throw coreStoreError
    }
    
    
    // MARK: Querying
    
    @nonobjc
    internal func queryValue<O, U: QueryableAttributeType>(
        _ selectTerms: [SelectTerm<O>],
        fetchRequest: Internals.CoreStoreFetchRequest<NSDictionary>
    ) throws(CoreStoreError) -> U? {

        var fetchResults: [Any]?
        var fetchError: (any Swift.Error)?
        self.performAndWait {
            
            do {
                
                fetchResults = try self.fetch(fetchRequest.staticCast())
            }
            catch {
                
                fetchError = error
            }
        }
        if let fetchResults = fetchResults {
            
            if let rawResult = fetchResults.first as? NSDictionary,
                let rawObject = rawResult[selectTerms.first!.keyPathString] as? U.QueryableNativeType {
                
                return Select<O, U>.ReturnType.cs_fromQueryableNativeType(rawObject)
            }
            return nil
        }
        let coreStoreError = CoreStoreError(fetchError)
        Internals.log(
            coreStoreError,
            "Failed executing fetch request."
        )
        throw coreStoreError
    }
    
    @nonobjc
    internal func queryValue<O>(
        _ selectTerms: [SelectTerm<O>],
        fetchRequest: Internals.CoreStoreFetchRequest<NSDictionary>
    ) throws(CoreStoreError) -> Any? {

        var fetchResults: [Any]?
        var fetchError: (any Swift.Error)?
        self.performAndWait {
            
            do {
                
                fetchResults = try self.fetch(fetchRequest.staticCast())
            }
            catch {
                
                fetchError = error
            }
        }
        if let fetchResults = fetchResults {
            
            if let rawResult = fetchResults.first as? NSDictionary,
                let rawObject = rawResult[selectTerms.first!.keyPathString] {
                
                return rawObject
            }
            return nil
        }
        let coreStoreError = CoreStoreError(fetchError)
        Internals.log(
            coreStoreError,
            "Failed executing fetch request."
        )
        throw coreStoreError
    }
    
    @nonobjc
    internal func queryAttributes(
        _ fetchRequest: Internals.CoreStoreFetchRequest<NSDictionary>
    ) throws(CoreStoreError) -> [[String: Any]] {

        var fetchResults: [Any]?
        var fetchError: (any Swift.Error)?
        self.performAndWait {
            
            do {
                
                fetchResults = try self.fetch(fetchRequest.staticCast())
            }
            catch {
                
                fetchError = error
            }
        }
        if let fetchResults = fetchResults {
            
            return NSDictionary.cs_fromQueryResultsNativeType(fetchResults)
        }
        let coreStoreError = CoreStoreError(fetchError)
        Internals.log(
            coreStoreError,
            "Failed executing fetch request."
        )
        throw coreStoreError
    }
    
    
    // MARK: Deleting
    
    @nonobjc
    internal func deleteAll<O: NSManagedObject>(
        _ fetchRequest: Internals.CoreStoreFetchRequest<O>
    ) throws(CoreStoreError) -> Int {

        var numberOfDeletedObjects: Int?
        var fetchError: (any Swift.Error)?
        self.performAndWait {
            
            Internals.autoreleasepool {

                do {
                    
                    let fetchResults = try self.fetch(fetchRequest.staticCast())
                    for object in fetchResults {
                        
                        self.delete(object)
                    }
                    numberOfDeletedObjects = fetchResults.count
                }
                catch {
                    
                    fetchError = error
                }
            }
        }
        if let numberOfDeletedObjects = numberOfDeletedObjects {

            return numberOfDeletedObjects
        }
        let coreStoreError = CoreStoreError(fetchError)
        Internals.log(
            coreStoreError,
            "Failed executing delete request."
        )
        throw coreStoreError
    }
}
