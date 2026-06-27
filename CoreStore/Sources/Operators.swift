//
//  Operators.swift
//  CoreStore
//
//  Copyright © 2023 John Rommel Estropia
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


infix operator .= : AssignmentPrecedence
infix operator .== : ComparisonPrecedence


infix operator &&? : LogicalConjunctionPrecedence
infix operator ||? : LogicalConjunctionPrecedence


// MARK: - ~

/**
 Connects multiple `KeyPathStringConvertible`s to create a type-safe chain usable in query/fetch expressions
```
let owner = dataStack.fetchOne(
    From<Pet>().where(
        (\.master ~ \.name) == "John"
    )
)
```
 */
infix operator ~ : AdditionPrecedence
