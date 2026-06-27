//
//  Value.swift
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

import CoreData
import Foundation


// MARK: - Deprecated

extension DynamicObject where Self: CoreStoreObject {
    
    @available(*, deprecated, message: """
    Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
    """)
    public typealias Value = ValueContainer<Self>
}

@available(*, deprecated, message: """
Legacy `Value.*`, `Transformable.*`, and `Relationship.*` declarations will soon be obsoleted. Please migrate your models and stores to new models that use `@Field.*` property wrappers. See: https://github.com/JohnEstropia/CoreStore?tab=readme-ov-file#new-field-property-wrapper-syntax
""")
public enum ValueContainer<O: CoreStoreObject> {}
