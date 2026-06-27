//
//  ObjectReader.swift
//  CoreStore
//
//  Copyright © 2021 John Rommel Estropia
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

#if canImport(Combine) && canImport(SwiftUI)

import Combine
import SwiftUI


// MARK: - ObjectReader

/**
 A container view that reads changes to an `ObjectPublisher`
 */
public struct ObjectReader<Object: DynamicObject, Content: View, Placeholder: View, Value>: View {
    
    // MARK: Internal
    
    /**
     Creates an instance that creates views for `ObjectPublisher` changes.
     
     - parameter objectPublisher: The `ObjectPublisher` that the `ObjectReader` instance uses to create views dynamically
     - parameter content: The view builder that receives an `Optional<ObjectSnapshot<O>>` instance and creates views dynamically.
     */
    public init(
        _ objectPublisher: ObjectPublisher<Object>?,
        @ViewBuilder content: @escaping (ObjectSnapshot<Object>) -> Content
    ) where Value == ObjectSnapshot<Object>, Placeholder == EmptyView {
        
        self._object = .init(objectPublisher)
        self.content = content
        self.placeholder = EmptyView.init
    }
    
    /**
     Creates an instance that creates views for `ObjectPublisher` changes.
     
     - parameter objectPublisher: The `ObjectPublisher` that the `ObjectReader` instance uses to create views dynamically
     - parameter content: The view builder that receives an `Optional<ObjectSnapshot<O>>` instance and creates views dynamically.
     - parameter placeholder: The view builder that creates a view for `nil` objects.
     */
    public init(
        _ objectPublisher: ObjectPublisher<Object>?,
        @ViewBuilder content: @escaping (ObjectSnapshot<Object>) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) where Value == ObjectSnapshot<Object> {
        
        self._object = .init(objectPublisher)
        self.content = content
        self.placeholder = placeholder
    }
    
    /**
     Creates an instance that creates views for `ObjectPublisher` changes.
     
     - parameter objectPublisher: The `ObjectPublisher` that the `ObjectReader` instance uses to create views dynamically
     - parameter keyPath: A `KeyPath` for a property in the `ObjectSnapshot` whose value will be sent to the views
     - parameter content: The view builder that receives the value from the property `KeyPath` and creates views dynamically.
     */
    public init(
        _ objectPublisher: ObjectPublisher<Object>?,
        keyPath: KeyPath<ObjectSnapshot<Object>, Value>,
        @ViewBuilder content: @escaping (Value) -> Content
    ) where Placeholder == EmptyView {
        
        self._object = .init(objectPublisher)
        self.content = {
            
            content($0[keyPath: keyPath])
        }
        self.placeholder = EmptyView.init
    }
    
    /**
     Creates an instance that creates views for `ObjectPublisher` changes.
     
     - parameter objectPublisher: The `ObjectPublisher` that the `ObjectReader` instance uses to create views dynamically
     - parameter keyPath: A `KeyPath` for a property in the `ObjectSnapshot` whose value will be sent to the views
     - parameter content: The view builder that receives the value from the property `KeyPath` and creates views dynamically.
     - parameter placeholder: The view builder that creates a view for `nil` objects.
     */
    public init(
        _ objectPublisher: ObjectPublisher<Object>?,
        keyPath: KeyPath<ObjectSnapshot<Object>, Value>,
        @ViewBuilder content: @escaping (Value) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) where Placeholder == EmptyView {
        
        self._object = .init(objectPublisher)
        self.content = {
            
            content($0[keyPath: keyPath])
        }
        self.placeholder = placeholder
    }
    
    
    // MARK: View
    
    public var body: some View {
        
        if let object = self.object {
            
            self.content(object)
        }
        else {
            
            self.placeholder()
        }
    }
    
    
    // MARK: Private
    
    @ObjectState
    private var object: ObjectSnapshot<Object>?
    
    private let content: (ObjectSnapshot<Object>) -> Content
    private let placeholder: () -> Placeholder
}

#endif
