//
//  QueryChainBuilder.swift
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


// MARK: - QueryChainBuilder

/**
 The fetch builder type used for a queries. A `QueryChainBuilder` is created from a `From` clause and then a `select(...)` chain.
 ```
 let averageAdultAge = dataStack.queryValue(
     From<MyPersonEntity>()
         .select(Int.self, .average(\.age))
         .where(\.age > 18)
 )
 ```
 */
public struct QueryChainBuilder<O: DynamicObject, R: SelectResultType>: QueryChainableBuilderType {
    
    // MARK: QueryChainableBuilderType
    
    public typealias ObjectType = O
    public typealias ResultType = R
    
    public var from: From<O>
    public var select: Select<O, R>
    public var queryClauses: [QueryClause] = []
}


// MARK: - QueryChainableBuilderType

/**
 Utility protocol for `QueryChainBuilder`. Used in fetch methods that support chained query builders.
 */
public protocol QueryChainableBuilderType {
    
    /**
     The `DynamicObject` type for the query
     */
    associatedtype ObjectType: DynamicObject
    
    /**
     The `SelectResultType` type for the query
     */
    associatedtype ResultType: SelectResultType
    
    /**
     The `From` clause specifies the source entity and source persistent store for the query
     */
    var from: From<ObjectType> { get set }
    
    /**
     The `Select` clause to be used for the query
     */
    var select: Select<ObjectType, ResultType> { get set }
    
    /**
     The `QueryClause`s to be used for the query
     */
    var queryClauses: [QueryClause] { get set }
}
