//
//  WhereClauseType.swift
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


// MARK: - WhereClauseType

/**
 Abstracts the `Where` clause for protocol utilities. Typically used only for utility method generic constraints.
 */
public protocol WhereClauseType: AnyWhereClause {
    
    /**
     The `DynamicObject` type associated with the clause
     */
    associatedtype ObjectType: DynamicObject
}

extension WhereClauseType {
    
    /**
     Combines two `Where` predicates together using `AND` operator.
     - Warning: This operator overload is a workaround for Swift generics' inability to constrain by inheritance (https://bugs.swift.org/browse/SR-5213). In effect, this is less type-safe than other overloads because it allows AND'ing clauses of unrelated `DynamicObject` types.
     */
    public static func && <TWhere: WhereClauseType>(
        left: Self,
        right: TWhere
    ) -> Where<Self.ObjectType> {

        return .init(
            NSCompoundPredicate(
                type: .and,
                subpredicates: [left.predicate, right.predicate]
            )
        )
    }

    /**
     Combines two `Where` predicates together using `AND` operator.
     - Warning: This operator overload is a workaround for Swift generics' inability to constrain by inheritance (https://bugs.swift.org/browse/SR-5213). In effect, this is less type-safe than other overloads because it allows AND'ing clauses of unrelated `DynamicObject` types.
     */
    public static func && <TWhere: WhereClauseType>(
        left: TWhere,
        right: Self
    ) -> Where<Self.ObjectType> {

        return .init(
            NSCompoundPredicate(
                type: .and,
                subpredicates: [left.predicate, right.predicate]
            )
        )
    }

    /**
     Combines two `Where` predicates together using `OR` operator.
     - Warning: This operator overload is a workaround for Swift generics' inability to constrain by inheritance (https://bugs.swift.org/browse/SR-5213). In effect, this is less type-safe than other overloads because it allows OR'ing clauses of unrelated `DynamicObject` types.
     */
    public static func || <TWhere: WhereClauseType>(
        left: Self,
        right: TWhere
    ) -> Where<Self.ObjectType> {

        return .init(
            NSCompoundPredicate(
                type: .or,
                subpredicates: [left.predicate, right.predicate]
            )
        )
    }

    /**
     Combines two `Where` predicates together using `OR` operator.
     - Warning: This operator overload is a workaround for Swift generics' inability to constrain by inheritance (https://bugs.swift.org/browse/SR-5213). In effect, this is less type-safe than other overloads because it allows OR'ing clauses of unrelated `DynamicObject` types.
     */
    public static func || <TWhere: WhereClauseType>(
        left: TWhere,
        right: Self
    ) -> Where<Self.ObjectType> {

        return .init(
            NSCompoundPredicate(
                type: .or,
                subpredicates: [left.predicate, right.predicate]
            )
        )
    }
}
