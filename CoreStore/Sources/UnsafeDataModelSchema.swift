//
//  UnsafeDataModelSchema.swift
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


// MARK: - UnsafeDataModelSchema

/**
 The `UnsafeDataModelSchema` describes models loaded directly from an existing `NSManagedObjectModel`. It is not advisable to continue using this model as its metadata are not available to CoreStore.
 */
public final class UnsafeDataModelSchema: DynamicSchema {
    
    /**
     Initializes a `UnsafeDataModelSchema` from an `NSManagedObjectModel`.
     ```
     CoreStoreDefaults.dataStack = DataStack(
         UnsafeDataModelSchema(modelName: "MyAppV1", model: model)
     )
     ```
     - parameter modelName: the model version, typically the file name of an *.xcdatamodeld file (without the file extension)
     - parameter model: the `NSManagedObjectModel`
     */
    public required init(
        modelName: ModelVersion,
        model: NSManagedObjectModel
    ) {

        self.modelVersion = modelName
        self.model = model
    }
    
    
    // MARK: DynamicSchema
    
    public let modelVersion: ModelVersion
    
    public func rawModel() -> NSManagedObjectModel {
        
        return self.model
    }
    
    
    // MARK: Private
    
    private let model: NSManagedObjectModel
}
