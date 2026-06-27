//
//  SectionMonitorBuilder.swift
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


// MARK: - SectionMonitorChainBuilder

/**
 The fetch builder type used for a sectioned `ListMonitor`. A `SectionMonitorChainBuilder` is created from a `From` clause and then a `sectionBy(...)` chain.
 ```
 let monitor = transaction.monitorSectionedList(
     From<MyPersonEntity>()
         .sectionBy(\.age, { "\($0!) years old" })
         .where(\.age > 18)
         .orderBy(.ascending(\.age))
 )
 ```
 */
public struct SectionMonitorChainBuilder<O: DynamicObject>: SectionMonitorBuilderType {
    
    // MARK: SectionMonitorBuilderType
    
    public var from: From<O>
    public var sectionBy: SectionBy<O>
    public var fetchClauses: [FetchClause] = []
}


// MARK: - SectionMonitorBuilderType

/**
 Utility protocol for `SectionMonitorChainBuilder`. Used in methods that support chained fetch builders.
 */
public protocol SectionMonitorBuilderType {
    
    /**
     The `DynamicObject` type for the `ListMonitor`
     */
    associatedtype ObjectType: DynamicObject
    
    /**
     The `From` clause specifies the source entity and source persistent store for the `ListMonitor`
     */
    var from: From<ObjectType> { get set }
    
    /**
     The `SectionBy` clause to be used for the `ListMonitor`
     */
    var sectionBy: SectionBy<ObjectType> { get set }
    
    /**
     The `FetchClause`s to be used for the `ListMonitor`
     */
    var fetchClauses: [FetchClause] { get set }
}
